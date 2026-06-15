"""Codex (``codex exec``) backend for the 3-arm benchmark — the second agent.

Implements :class:`fvk_bench.runner.AgentRunner`. Mirrors
:mod:`fvk_bench.claude_runner`'s process robustness (scrubbed env,
process-group timeout kill, always-persisted raw stdout/stderr) but speaks
Codex's surface:

- fresh (baseline):  ``codex exec <prompt> ...``
- fork (fvk/control): ``codex exec resume <baseline_id> <prompt> ...``

Pinned fairness constants live in :mod:`fvk_bench.config` (``CODEX_*``): model
``gpt-5.5``, reasoning effort ``xhigh``, sandbox ``workspace-write``. The fix
must be writable, so a read-only sandbox is impossible; *execution* (running
tests) is forbidden by the prompt, not the sandbox — Codex reads/searches via
shell, so a no-exec sandbox would also block reading. ``--ignore-user-config``
drops the user's ``config.toml`` (model/provider/plugins/MCP) while subscription
auth under ``CODEX_HOME`` is preserved (the documented split: ignore-user-config
skips config.toml only, auth still uses CODEX_HOME).

Two Codex facts this module cannot assume and that the first run on the real
machine must confirm (see the inline notes):
1. whether ``codex exec resume`` appends to the baseline rollout in place or
   spawns a fresh rollout — :meth:`CodexRunner.run_fork` is written to keep
   baseline purity either way (snapshot once, restore before each later fork);
2. which flags ``codex exec resume`` accepts (``--json``/``-o``/``--sandbox``
   may need ``-c`` config overrides instead). :func:`build_argv` centralises the
   option list so a probe-driven adjustment is one edit.
"""

from __future__ import annotations

import json
import os
import re
import shutil
import signal
import subprocess
import time
from collections import Counter
from pathlib import Path

from fvk_bench import config
from fvk_bench.claude_runner import ClaudeResult as AgentResult


def _coerce_text(data: str | bytes | None) -> str:
    """Normalize partial pipe output to ``str`` (duplicated from claude_runner,
    matching the house style of not importing a sibling module's private)."""
    if data is None:
        return ""
    if isinstance(data, bytes):
        return data.decode("utf-8", errors="replace")
    return data


#: Where Codex writes session rollouts and reads subscription auth.
def _codex_home() -> Path:
    return Path(os.environ.get("CODEX_HOME") or (Path.home() / ".codex"))


#: Workspace-relative directory holding this benchmark's saved Codex artifacts
#: (per-session transcript copies + the baseline rollout snapshot). Kept inside
#: the hash-excluded ``.fvk_bench/`` tree so it never perturbs the core hash.
_CODEX_DIR = (".fvk_bench", "codex")

#: rollout ``response_item`` payload types that represent a tool/command call.
_TOOL_PAYLOAD_TYPES = (
    "function_call",
    "local_shell_call",
    "custom_tool_call",
    "tool_call",
    "exec_command",
)

#: Shell-command substrings that indicate the agent tried to *execute*
#: verification (forbidden by the prompt). Warning-level only — Codex cannot be
#: hard-prevented from running commands, so this informs, it does not fail.
_EXEC_TEST_RE = re.compile(
    r"\b(pytest|py\.test|tox|nox|unittest|nosetests|"
    r"python[0-9.]*\s+-m\s+(?:pytest|unittest)|make\s+\w*test)\b"
)


def build_argv(
    prompt: str,
    arm: str,
    *,
    resume_id: str | None = None,
    codex_bin: str = "codex",
    model: str = config.CODEX_MODEL,
    effort: str = config.CODEX_EFFORT,
    sandbox: str = config.CODEX_SANDBOX,
    cwd: Path | None = None,
    last_message_file: Path | None = None,
) -> list[str]:
    """Build the pinned ``codex exec`` argv for one arm session.

    ``resume_id`` switches fresh (``codex exec <prompt>``) to fork
    (``codex exec ... resume <id> <prompt>``). The installed CLI parses
    ``resume`` as a subcommand with a narrower option surface, so parent
    ``codex exec`` options such as ``--sandbox`` and ``-C`` must precede the
    subcommand for forked sessions.
    """
    argv = [codex_bin, "exec"]
    opts = [
        "-m", model,
        "-c", f"model_reasoning_effort={effort}",
        "--sandbox", sandbox,
        "--skip-git-repo-check",
        "--ignore-user-config",
        "--json",
    ]
    if cwd is not None:
        opts += ["-C", str(cwd)]
    if last_message_file is not None:
        opts += ["-o", str(last_message_file)]
    if resume_id is not None:
        argv += opts + ["resume", resume_id, prompt]
    else:
        argv += [prompt] + opts
    return argv


def _run_process(
    argv: list[str], ws: Path, arm: str, timeout: int
) -> tuple[str, str, int | None, bool, float]:
    """Run ``argv`` in ``ws`` with the scrubbed env; persist raw output always.

    Mirrors :func:`fvk_bench.claude_runner.run_arm_session`'s process handling:
    own process group so a timeout SIGKILLs the whole tree, bounded drain, and a
    finally-guard orphan kill. Returns
    ``(stdout, stderr, returncode, timed_out, duration_seconds)``.
    """
    raw_dir = ws / ".fvk_bench" / "raw"
    raw_dir.mkdir(parents=True, exist_ok=True)
    stdout_path = raw_dir / f"{arm}.stdout.jsonl"
    stderr_path = raw_dir / f"{arm}.stderr.txt"

    timed_out = False
    start = time.monotonic()
    try:
        proc = subprocess.Popen(
            argv,
            cwd=ws,
            env=config.session_env(),
            stdin=subprocess.DEVNULL,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
            start_new_session=True,
        )
    except OSError as exc:
        stdout_path.write_text("", encoding="utf-8")
        stderr_path.write_text(f"spawn_failure:{exc}\n", encoding="utf-8")
        return "", f"spawn_failure:{exc}", None, False, time.monotonic() - start

    stdout = stderr = ""
    try:
        try:
            stdout, stderr = proc.communicate(timeout=timeout)
        except subprocess.TimeoutExpired:
            timed_out = True
            try:
                os.killpg(os.getpgid(proc.pid), signal.SIGKILL)
            except ProcessLookupError:
                pass
            try:
                stdout, stderr = proc.communicate(timeout=30)
            except subprocess.TimeoutExpired as drain_exc:
                stdout = _coerce_text(drain_exc.stdout)
                stderr = _coerce_text(drain_exc.stderr)
                for stream in (proc.stdout, proc.stderr):
                    if stream is not None:
                        stream.close()
                try:
                    proc.wait(timeout=5)
                except subprocess.TimeoutExpired:
                    pass
    finally:
        if proc.poll() is None:
            try:
                os.killpg(os.getpgid(proc.pid), signal.SIGKILL)
            except ProcessLookupError:
                pass
            proc.wait(timeout=10)
    duration = time.monotonic() - start

    stdout_path.write_text(stdout or "", encoding="utf-8")
    stderr_path.write_text(stderr or "", encoding="utf-8")
    return stdout or "", stderr or "", proc.returncode, timed_out, duration


def _parse_events(stdout: str) -> list[dict]:
    """Parse ``codex exec --json`` JSONL stdout into event dicts (lenient)."""
    events: list[dict] = []
    for line in stdout.splitlines():
        line = line.strip()
        if not line:
            continue
        try:
            obj = json.loads(line)
        except ValueError:
            continue
        if isinstance(obj, dict):
            events.append(obj)
    return events


def _session_meta_id(rollout: Path) -> str | None:
    """Read the ``session_meta.payload.id`` from a rollout's first lines."""
    try:
        with open(rollout, encoding="utf-8", errors="replace") as fh:
            for _ in range(5):
                line = fh.readline()
                if not line:
                    break
                try:
                    obj = json.loads(line)
                except ValueError:
                    continue
                if obj.get("type") == "session_meta":
                    payload = obj.get("payload") or {}
                    sid = payload.get("id")
                    if isinstance(sid, str):
                        return sid
    except OSError:
        return None
    return None


def _event_thread_id(events: list[dict]) -> str | None:
    """Return the Codex ``thread.started`` id from stdout events, if present."""
    for event in events:
        if event.get("type") == "thread.started":
            sid = event.get("thread_id")
            if isinstance(sid, str) and sid:
                return sid
    return None


def _find_rollout_by_id(session_id: str) -> Path | None:
    """Find the live rollout file whose name contains ``session_id``."""
    sessions = _codex_home() / "sessions"
    if not sessions.is_dir():
        return None
    return next((p for p in sessions.rglob(f"rollout-*{session_id}*.jsonl")), None)


def _discover_rollout(start_wall: float, resume_id: str | None) -> tuple[str | None, Path | None]:
    """Find the rollout this run produced and its session id.

    Picks, among rollouts touched at/after ``start_wall`` under
    ``CODEX_HOME/sessions``, the newest; when ``resume_id`` is given a file whose
    name contains it is preferred (covers append-in-place resume, where no new
    file appears and the touched file is the baseline's own rollout).
    """
    sessions = _codex_home() / "sessions"
    if not sessions.is_dir():
        return None, None
    slack = 2.0
    candidates: list[Path] = []
    preferred: Path | None = None
    for path in sessions.rglob("rollout-*.jsonl"):
        try:
            mtime = path.stat().st_mtime
        except OSError:
            continue
        if mtime + slack < start_wall:
            continue
        candidates.append(path)
        if resume_id and resume_id in path.name:
            preferred = path
    chosen = preferred
    if chosen is None and candidates:
        chosen = max(candidates, key=lambda p: p.stat().st_mtime)
    if chosen is None:
        return (resume_id, None)
    return (_session_meta_id(chosen) or resume_id, chosen)


def _save_transcript(ws: Path, session_id: str, rollout: Path | None) -> Path | None:
    """Copy ``rollout`` into the hash-excluded codex dir, keyed by session id.

    A stable per-run copy that survives the baseline-rollout snapshot/restore
    dance and any later resume, so audit and harvest read a fixed file.
    """
    if rollout is None or not rollout.exists():
        return None
    dest_dir = ws.joinpath(*_CODEX_DIR)
    dest_dir.mkdir(parents=True, exist_ok=True)
    dest = dest_dir / f"{session_id}.rollout.jsonl"
    shutil.copy2(rollout, dest)
    return dest


class CodexRunner:
    """:class:`fvk_bench.runner.AgentRunner` backed by the ``codex`` CLI."""

    name = "codex"

    def __init__(self, *, codex_bin: str = "codex", model: str = config.CODEX_MODEL):
        self._bin = codex_bin
        self._model = model

    def new_session_id(self) -> None:
        """Codex assigns its own session id; it is unknown until after the run."""
        return None

    def _persist_prompt(self, ws: Path, arm: str, prompt: str) -> None:
        prompt_path = ws / ".fvk_bench" / "prompts" / f"{arm}.md"
        prompt_path.parent.mkdir(parents=True, exist_ok=True)
        prompt_path.write_text(prompt, encoding="utf-8")

    def _result(
        self, ws: Path, arm: str, stdout: str, stderr: str, rc: int | None,
        timed_out: bool, duration: float, resume_id: str | None,
    ) -> AgentResult:
        if stderr.startswith("spawn_failure:"):
            return AgentResult(
                ok=False, session_id=None, num_turns=None, subtype=None,
                duration_seconds=duration, raw_json=None, error=stderr.strip(),
            )
        events = _parse_events(stdout)
        # Session id: stdout's thread.started event belongs to this exact
        # process. Falling back to rollout mtime is only safe when stdout lacks
        # that id; concurrent sessions can otherwise race and all select the
        # newest rollout.
        event_session_id = _event_thread_id(events)
        if event_session_id:
            session_id = event_session_id
            rollout = _find_rollout_by_id(event_session_id)
        else:
            session_id, rollout = _discover_rollout(time.time() - duration, resume_id)
        if session_id:
            _save_transcript(ws, session_id, rollout)
        num_turns = sum(
            1 for e in events if e.get("type") == "event_msg"
            and isinstance(e.get("payload"), dict)
            and e["payload"].get("type") == "task_started"
        ) or None
        agent_errored = any(
            e.get("type") == "event_msg"
            and isinstance(e.get("payload"), dict)
            and e["payload"].get("type") in ("error", "task_failed")
            for e in events
        )
        if timed_out:
            error = "timeout"
        elif rc not in (0, None):
            error = f"nonzero_exit:{rc}"
        elif not events:
            error = "bad_output"
        elif agent_errored:
            error = "agent_error:codex"
        else:
            error = None
        return AgentResult(
            ok=error is None, session_id=session_id, num_turns=num_turns,
            subtype=None, duration_seconds=duration, raw_json={"events": len(events)},
            error=error,
        )

    def run_fresh(
        self, ws: Path, arm: str, prompt: str, *, session_id: str | None = None,
        timeout: int = config.ARM_TIMEOUT_SECONDS, max_turns: int | None = None,
    ) -> AgentResult:
        ws = Path(ws)
        if not ws.is_dir():
            raise RuntimeError(
                f"workspace {ws} is not an existing directory — scaffold the "
                "workspace before running an arm session"
            )
        self._persist_prompt(ws, arm, prompt)
        last_msg = ws / ".fvk_bench" / "raw" / f"{arm}.last.txt"
        argv = build_argv(
            prompt, arm, codex_bin=self._bin, model=self._model,
            cwd=ws, last_message_file=last_msg,
        )
        stdout, stderr, rc, timed_out, duration = _run_process(argv, ws, arm, timeout)
        return self._result(ws, arm, stdout, stderr, rc, timed_out, duration, None)

    def run_fork(
        self, ws: Path, arm: str, prompt: str, baseline_session_id: str, *,
        timeout: int = config.ARM_TIMEOUT_SECONDS, max_turns: int | None = None,
    ) -> AgentResult:
        ws = Path(ws)
        if not ws.is_dir():
            raise RuntimeError(
                f"workspace {ws} is not an existing directory — scaffold the "
                "workspace before running an arm session"
            )
        self._persist_prompt(ws, arm, prompt)
        self._snapshot_or_restore_baseline(ws, baseline_session_id)
        last_msg = ws / ".fvk_bench" / "raw" / f"{arm}.last.txt"
        argv = build_argv(
            prompt, arm, resume_id=baseline_session_id, codex_bin=self._bin,
            model=self._model, cwd=ws, last_message_file=last_msg,
        )
        stdout, stderr, rc, timed_out, duration = _run_process(argv, ws, arm, timeout)
        return self._result(
            ws, arm, stdout, stderr, rc, timed_out, duration, baseline_session_id
        )

    def _snapshot_or_restore_baseline(self, ws: Path, baseline_session_id: str) -> None:
        """Keep the baseline rollout pristine across both fork arms.

        First fork: snapshot the baseline rollout. Later forks: restore it from
        the snapshot, undoing any in-place append a prior resume may have made.
        Correct whether ``codex exec resume`` appends in place (restore matters)
        or spawns a fresh rollout (restore is a harmless identical rewrite).
        No-op if the baseline rollout cannot be located.
        """
        # The live rollout under CODEX_HOME (not the saved copy) is what resume
        # reads, so it is what must be kept pristine.
        sessions = _codex_home() / "sessions"
        live = next(
            (p for p in sessions.rglob(f"rollout-*{baseline_session_id}*.jsonl")),
            None,
        ) if sessions.is_dir() else None
        if live is None:
            return
        snap = ws.joinpath(*_CODEX_DIR) / "baseline.rollout.snapshot"
        snap.parent.mkdir(parents=True, exist_ok=True)
        if snap.exists():
            shutil.copy2(snap, live)
        else:
            shutil.copy2(live, snap)

    def transcript_path(self, ws: Path, session_id: str) -> Path | None:
        if not session_id:
            return None
        saved = ws.joinpath(*_CODEX_DIR) / f"{session_id}.rollout.jsonl"
        if saved.exists():
            return saved
        sessions = _codex_home() / "sessions"
        if sessions.is_dir():
            return next(
                (p for p in sessions.rglob(f"rollout-*{session_id}*.jsonl")), None
            )
        return None

    def audit_transcript(self, path: Path) -> dict:
        """Audit a Codex rollout for tool-surface cleanliness + exec attempts.

        ``violations`` (MCP/plugin tool calls that ``--ignore-user-config``
        should have prevented) flip ``ok`` to False. ``exec_warnings`` (shell
        commands that ran tests/verification, forbidden by the prompt) are
        recorded but never flip ``ok`` — Codex cannot be hard-prevented from
        executing, so this informs rather than fails the arm.
        """
        tool_uses: Counter = Counter()
        exec_warnings: list[str] = []
        violations: set[str] = set()
        unparseable = 0
        total = 0
        with open(path, encoding="utf-8", errors="replace") as fh:
            for lineno, raw in enumerate(fh, start=1):
                total = lineno
                try:
                    obj = json.loads(raw)
                except ValueError:
                    unparseable += 1
                    continue
                if not isinstance(obj, dict) or obj.get("type") != "response_item":
                    continue
                payload = obj.get("payload")
                if not isinstance(payload, dict):
                    continue
                if payload.get("type") not in _TOOL_PAYLOAD_TYPES:
                    continue
                name = payload.get("name") or payload.get("type")
                if isinstance(name, str):
                    tool_uses[name] += 1
                    if name.startswith("mcp") or name.startswith("plugin"):
                        violations.add(name)
                command = _command_text(payload)
                if command and _EXEC_TEST_RE.search(command):
                    exec_warnings.append(command[:200])
        return {
            "ok": len(violations) == 0,
            "tool_uses": dict(tool_uses),
            "violations": sorted(violations),
            "exec_warnings": exec_warnings,
            "unparseable_lines": unparseable,
            "lines": total,
        }

    def version(self) -> str | None:
        try:
            proc = subprocess.run(
                [self._bin, "--version"], capture_output=True, text=True, timeout=15
            )
        except OSError:
            return None
        if proc.returncode != 0:
            return None
        return proc.stdout.strip() or None


def _command_text(payload: dict) -> str | None:
    """Best-effort shell-command string from a tool-call payload (schema-lenient)."""
    for key in ("command", "cmd"):
        val = payload.get(key)
        if isinstance(val, str):
            return val
        if isinstance(val, list):
            return " ".join(str(x) for x in val)
    action = payload.get("action")
    if isinstance(action, dict):
        return _command_text(action)
    args = payload.get("arguments")
    if isinstance(args, str):
        return args
    return None

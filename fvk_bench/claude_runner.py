"""Hermetic Claude CLI invocation, transcript discovery, and session audits.

This module is the ONLY place the ``claude`` binary is ever invoked. It owns
the full standardization core of the benchmark:

- :func:`build_argv` produces the exact pinned flag set from
  :mod:`fvk_bench.config` — fresh sessions get ``--session-id``, fork sessions
  get ``--resume <id> --fork-session`` (exactly one, never both).
- :func:`run_arm_session` runs that argv inside the workspace with the
  scrubbed :func:`fvk_bench.config.session_env` environment (no ``ANTHROPIC_*``
  / ``CLAUDE_*`` leakage), enforces a wall-clock timeout by killing the whole
  process group, always persists raw stdout/stderr under
  ``<ws>/.fvk_bench/raw/``, and parses the JSON result envelope.
- :func:`transcript_path` locates the session transcript that the CLI writes
  under ``~/.claude/projects/<munged-cwd>/<session-id>.jsonl``.
- :func:`audit_transcript` is the empirical session-cleanliness check: it
  censuses ``tool_use`` blocks against the pinned 5-tool surface and flags
  marker strings that indicate injected tool/agent listings.
"""

import json
import os
import re
import signal
import subprocess
import time
import uuid
from collections import Counter
from dataclasses import dataclass
from pathlib import Path

from fvk_bench import config

#: Verbatim value for ``--mcp-config``: zero MCP servers, regardless of any
#: machine-level configuration (paired with ``--strict-mcp-config``).
_EMPTY_MCP_CONFIG = '{"mcpServers":{}}'

#: Raw-text markers whose presence in a transcript line indicates injected
#: tool/agent listings (deferred-tool attachments, MCP servers, agent rosters).
_AUDIT_MARKERS = ("Available agent types", "mcp__", "<functions>")


def _coerce_text(data: str | bytes | None) -> str:
    """Normalize partial pipe output to ``str``.

    :class:`subprocess.TimeoutExpired` carries whatever was read so far as
    *bytes* even for text-mode pipes (CPython joins the raw chunks), and may
    carry ``None`` when nothing was read at all.
    """
    if data is None:
        return ""
    if isinstance(data, bytes):
        return data.decode("utf-8", errors="replace")
    return data


@dataclass
class ClaudeResult:
    """Outcome of one ``claude`` invocation.

    ``error`` is ``None`` on a clean run, else one of ``"timeout"``,
    ``"nonzero_exit:<n>"``, ``"bad_json"``, ``"agent_error:<subtype>"`` (zero
    exit, parsed envelope, but ``is_error`` truthy) or ``"spawn_failure:<msg>"``
    (the ``claude`` binary could not be spawned at all).

    Invariant: ``ok=False ⇔ error is not None`` — ``ok`` is exactly
    ``error is None``, never anything subtler.
    """

    ok: bool
    session_id: str | None
    num_turns: int | None
    subtype: str | None
    duration_seconds: float
    raw_json: dict | None
    error: str | None


def build_argv(
    prompt: str,
    arm: str,
    *,
    session_id: str | None = None,
    resume_id: str | None = None,
    claude_bin: str = "claude",
    model: str = config.MODEL,
    max_turns: int | None = None,
) -> list[str]:
    """Build the exact pinned ``claude`` argv for one arm session.

    Exactly one of ``session_id`` (fresh session) or ``resume_id`` (fork from
    a frozen baseline session) must be provided.

    Raises:
        ValueError: if neither or both of ``session_id``/``resume_id`` are given.
    """
    if (session_id is None) == (resume_id is None):
        raise ValueError(
            "exactly one of session_id (fresh) or resume_id (fork) is required"
        )
    turns = max_turns if max_turns is not None else config.MAX_TURNS[arm]
    argv = [
        claude_bin,
        "-p",
        prompt,
        "--model",
        model,
        "--effort",
        config.EFFORT,
        "--max-turns",
        str(turns),
        "--output-format",
        "json",
        "--permission-mode",
        config.PERMISSION_MODE,
        "--setting-sources",
        config.SETTING_SOURCES,
        "--disable-slash-commands",
        "--tools",
        config.TOOLS,
        "--strict-mcp-config",
        "--mcp-config",
        _EMPTY_MCP_CONFIG,
    ]
    if session_id is not None:
        argv += ["--session-id", session_id]
    else:
        argv += ["--resume", resume_id, "--fork-session"]
    return argv


def run_arm_session(
    ws: Path,
    arm: str,
    prompt_text: str,
    *,
    session_id: str | None = None,
    resume_id: str | None = None,
    timeout: int = config.ARM_TIMEOUT_SECONDS,
    claude_bin: str = "claude",
    model: str = config.MODEL,
    max_turns: int | None = None,
) -> ClaudeResult:
    """Run one arm session in workspace ``ws`` and capture everything.

    ``max_turns`` overrides the pinned per-arm turn budget (used only by
    short probe sessions such as the doctor canary — benchmark arms always
    run with the pinned :data:`fvk_bench.config.MAX_TURNS` default).

    ``ws`` must already exist (scaffolded by the workspace step) — running an
    arm against a missing directory is a sequencing bug, not something to
    paper over with ``mkdir``. The prompt is persisted to
    ``<ws>/.fvk_bench/prompts/<arm>.md`` (artifact of record) and passed
    verbatim via argv. The child runs with cwd ``ws``, the scrubbed allowlist
    environment, stdin pinned to ``/dev/null`` (the real CLI consumes piped
    stdin as prompt context — determinism demands there be none), and its own
    process group so a timeout kills the entire process tree; a try/finally
    guard ensures no detached ``claude`` survives this call on *any* exception
    path (``KeyboardInterrupt`` included). Raw stdout/stderr are always
    written to ``<ws>/.fvk_bench/raw/<arm>.stdout.json`` / ``<arm>.stderr.txt``,
    even on timeout, spawn failure or other failure — stdout is parsed for
    forensics whenever possible.

    Raises:
        RuntimeError: if ``ws`` is not an existing directory.
    """
    ws = Path(ws)
    if not ws.is_dir():
        raise RuntimeError(
            f"workspace {ws} is not an existing directory — scaffold the "
            "workspace before running an arm session"
        )
    prompt_path = ws / ".fvk_bench" / "prompts" / f"{arm}.md"
    prompt_path.parent.mkdir(parents=True, exist_ok=True)
    prompt_path.write_text(prompt_text, encoding="utf-8")

    argv = build_argv(
        prompt_text,
        arm,
        session_id=session_id,
        resume_id=resume_id,
        claude_bin=claude_bin,
        model=model,
        max_turns=max_turns,
    )

    raw_dir = ws / ".fvk_bench" / "raw"
    raw_dir.mkdir(parents=True, exist_ok=True)
    stdout_path = raw_dir / f"{arm}.stdout.json"
    stderr_path = raw_dir / f"{arm}.stderr.txt"

    timed_out = False
    start = time.monotonic()
    try:
        proc = subprocess.Popen(
            argv,
            cwd=ws,
            env=config.session_env(),
            stdin=subprocess.DEVNULL,  # determinism: no piped prompt context
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
            start_new_session=True,  # own process group: timeout kills the whole tree
        )
    except OSError as exc:
        # Spawn failures (missing binary, EACCES, ...) still leave forensics.
        stdout_path.write_text("", encoding="utf-8")
        stderr_path.write_text(f"spawn_failure:{exc}\n", encoding="utf-8")
        return ClaudeResult(
            ok=False,
            session_id=None,
            num_turns=None,
            subtype=None,
            duration_seconds=time.monotonic() - start,
            raw_json=None,
            error=f"spawn_failure:{exc}",
        )

    stdout: str = ""
    stderr: str = ""
    try:
        try:
            stdout, stderr = proc.communicate(timeout=timeout)
        except subprocess.TimeoutExpired:
            timed_out = True
            try:
                os.killpg(os.getpgid(proc.pid), signal.SIGKILL)
            except ProcessLookupError:
                pass  # process group died between the timeout and the kill
            try:
                # Bounded drain: the group is SIGKILLed, but a pipe inherited
                # by something outside the group could keep it open forever.
                stdout, stderr = proc.communicate(timeout=30)
            except subprocess.TimeoutExpired as drain_exc:
                # Record whatever was captured (possibly empty), abandon the
                # pipes rather than hang, and best-effort reap the child.
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
        # Orphan guard: whatever happened above (KeyboardInterrupt included),
        # no detached claude may survive the parent.
        if proc.poll() is None:
            try:
                os.killpg(os.getpgid(proc.pid), signal.SIGKILL)
            except ProcessLookupError:
                pass
            proc.wait(timeout=10)
    duration = time.monotonic() - start

    stdout_path.write_text(stdout or "", encoding="utf-8")
    stderr_path.write_text(stderr or "", encoding="utf-8")

    parsed: dict | None = None
    try:
        candidate = json.loads(stdout or "")
        if isinstance(candidate, dict):
            parsed = candidate
    except ValueError:
        parsed = None

    rc = proc.returncode
    if timed_out:
        error = "timeout"
    elif rc != 0:
        # Still parsed above when possible: a session_id from a failed run is
        # useful forensics (e.g. to harvest its transcript).
        error = f"nonzero_exit:{rc}"
    elif parsed is None:
        error = "bad_json"
    elif parsed.get("is_error"):
        error = f"agent_error:{parsed.get('subtype') or 'unknown'}"
    else:
        error = None

    return ClaudeResult(
        ok=error is None,
        session_id=parsed.get("session_id") if parsed else None,
        num_turns=parsed.get("num_turns") if parsed else None,
        subtype=parsed.get("subtype") if parsed else None,
        duration_seconds=duration,
        raw_json=parsed,
        error=error,
    )


def _munge(p: str) -> str:
    """Map a cwd path to the directory name `claude` uses under ~/.claude/projects."""
    return re.sub(r"[^A-Za-z0-9-]", "-", p)


def transcript_path(ws: Path, session_id: str) -> Path | None:
    """Locate the transcript jsonl for ``session_id`` run with cwd ``ws``.

    Primary location is ``~/.claude/projects/<munged-cwd>/<session-id>.jsonl``;
    if the munging scheme ever drifts, a glob across all project directories is
    the fallback. Returns ``None`` when no transcript exists.
    """
    projects = Path.home() / ".claude" / "projects"
    primary = projects / _munge(str(Path(ws).resolve())) / f"{session_id}.jsonl"
    if primary.exists():
        return primary
    return next(Path.home().glob(f".claude/projects/*/{session_id}.jsonl"), None)


def audit_transcript(
    jsonl_path: Path,
    allowed_tools: tuple[str, ...] | None = None,
) -> dict:
    """Audit a session transcript for tool-surface cleanliness.

    ``allowed_tools`` defaults to the pinned :data:`fvk_bench.config.TOOLS`
    surface so the audit can never drift from the experiment specification;
    pass an explicit tuple to audit against a different surface.

    Streams the jsonl line by line (transcripts can be large) and returns::

        {"ok": bool,                # no tool_use outside allowed_tools
         "tool_uses": {name: count} across all assistant messages,
         "violations": sorted tool names used but not allowed,
         "marker_warnings": 1-based line numbers whose raw text contains an
                            injected-listing marker (warning only — does not
                            flip ``ok``),
         "unparseable_lines": int, "lines": int}

    Unparseable lines are counted and skipped, never fatal; undecodable bytes
    are replaced rather than raised so an audit cannot crash on a weird
    transcript.
    """
    if allowed_tools is None:
        allowed_tools = tuple(config.TOOLS.split(","))
    tool_uses: Counter = Counter()
    marker_warnings: list[int] = []
    unparseable = 0
    total = 0
    with open(jsonl_path, encoding="utf-8", errors="replace") as fh:
        for lineno, raw in enumerate(fh, start=1):
            total = lineno
            if any(marker in raw for marker in _AUDIT_MARKERS):
                marker_warnings.append(lineno)
            try:
                obj = json.loads(raw)
            except ValueError:
                unparseable += 1
                continue
            if not isinstance(obj, dict) or obj.get("type") != "assistant":
                continue
            message = obj.get("message")
            if not isinstance(message, dict):
                continue
            content = message.get("content")
            if not isinstance(content, list):
                continue
            for block in content:
                if isinstance(block, dict) and block.get("type") == "tool_use":
                    name = block.get("name")
                    if name is not None:
                        tool_uses[name] += 1
    violations = sorted({name for name in tool_uses if name not in allowed_tools})
    return {
        "ok": len(violations) == 0,
        "tool_uses": dict(tool_uses),
        "violations": violations,
        "marker_warnings": marker_warnings,
        "unparseable_lines": unparseable,
        "lines": total,
    }


class ClaudeRunner:
    """:class:`fvk_bench.runner.AgentRunner` backed by the ``claude`` CLI.

    A thin adapter over this module's free functions — it adds no behavior,
    so the Claude arm runs byte-for-byte as before. ``transcript_path`` and
    ``audit_transcript`` deliberately call the module-level functions by global
    name (not captured references) so tests that monkeypatch
    ``claude_runner.transcript_path`` keep working through the adapter.
    """

    name = "claude"

    def __init__(self, *, claude_bin: str = "claude", model: str = config.MODEL):
        self._bin = claude_bin
        self._model = model

    def new_session_id(self) -> str:
        """Claude takes a caller-chosen ``--session-id``, so the id is known
        before the run — forensics survive a mid-run crash."""
        return str(uuid.uuid4())

    def run_fresh(
        self,
        ws: Path,
        arm: str,
        prompt: str,
        *,
        session_id: str | None = None,
        timeout: int = config.ARM_TIMEOUT_SECONDS,
        max_turns: int | None = None,
    ) -> ClaudeResult:
        if session_id is None:
            session_id = self.new_session_id()
        return run_arm_session(
            ws, arm, prompt,
            session_id=session_id, timeout=timeout,
            claude_bin=self._bin, model=self._model, max_turns=max_turns,
        )

    def run_fork(
        self,
        ws: Path,
        arm: str,
        prompt: str,
        baseline_session_id: str,
        *,
        timeout: int = config.ARM_TIMEOUT_SECONDS,
        max_turns: int | None = None,
    ) -> ClaudeResult:
        return run_arm_session(
            ws, arm, prompt,
            resume_id=baseline_session_id, timeout=timeout,
            claude_bin=self._bin, model=self._model, max_turns=max_turns,
        )

    def transcript_path(self, ws: Path, session_id: str) -> Path | None:
        return transcript_path(ws, session_id)

    def audit_transcript(self, path: Path) -> dict:
        return audit_transcript(path)

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

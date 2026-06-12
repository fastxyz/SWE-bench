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


@dataclass
class ClaudeResult:
    """Outcome of one ``claude`` invocation.

    ``error`` is ``None`` on a clean run, else one of ``"timeout"``,
    ``"nonzero_exit:<n>"`` or ``"bad_json"``. ``ok`` additionally requires the
    parsed envelope to not carry ``is_error``; an envelope with
    ``is_error: true`` on a zero exit yields ``ok=False`` with ``error=None``.
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
) -> ClaudeResult:
    """Run one arm session in workspace ``ws`` and capture everything.

    The prompt is persisted to ``<ws>/.fvk_bench/prompts/<arm>.md`` (artifact
    of record) and passed verbatim via argv. The child runs with cwd ``ws``,
    the scrubbed allowlist environment, and its own process group so a timeout
    kills the entire process tree. Raw stdout/stderr are always written to
    ``<ws>/.fvk_bench/raw/<arm>.stdout.json`` / ``<arm>.stderr.txt``, even on
    timeout or failure — stdout is parsed for forensics whenever possible.
    """
    ws = Path(ws)
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
    )

    timed_out = False
    start = time.monotonic()
    proc = subprocess.Popen(
        argv,
        cwd=ws,
        env=config.session_env(),
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
        start_new_session=True,  # own process group: timeout kills the whole tree
    )
    try:
        stdout, stderr = proc.communicate(timeout=timeout)
    except subprocess.TimeoutExpired:
        timed_out = True
        try:
            os.killpg(os.getpgid(proc.pid), signal.SIGKILL)
        except ProcessLookupError:
            pass  # process group died between the timeout and the kill
        stdout, stderr = proc.communicate()  # drain whatever was buffered
    duration = time.monotonic() - start

    raw_dir = ws / ".fvk_bench" / "raw"
    raw_dir.mkdir(parents=True, exist_ok=True)
    (raw_dir / f"{arm}.stdout.json").write_text(stdout or "", encoding="utf-8")
    (raw_dir / f"{arm}.stderr.txt").write_text(stderr or "", encoding="utf-8")

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
    else:
        error = None

    ok = (
        not timed_out
        and rc == 0
        and parsed is not None
        and not parsed.get("is_error", False)
    )
    return ClaudeResult(
        ok=ok,
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
    allowed_tools: tuple[str, ...] = ("Read", "Write", "Edit", "Glob", "Grep"),
) -> dict:
    """Audit a session transcript for tool-surface cleanliness.

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

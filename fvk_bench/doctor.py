"""Preflight checks and the empirical session-cleanliness canary.

``run_checks`` probes the host (binaries, arch, python, imports, docker,
disk, workspace ancestry, leaky env) and returns verdict tuples — it never
prints; rendering belongs to the CLI. ``run_canary`` is the
trust-nothing-verify-everything probe: it runs one real (cheap) Claude
session with the exact pinned production flag set in a throwaway workspace,
then audits the resulting transcript to prove the session saw exactly the
pinned 5-tool surface and no injected tool/agent/MCP listings.

Verdict encoding for checks: ``ok=True`` passed, ``ok=False`` hard failure,
``ok=None`` warning (suspicious but not blocking).
"""

import importlib.util
import os
import platform
import shutil
import subprocess
import sys
import tempfile
import uuid
from pathlib import Path

from fvk_bench import claude_runner, config

#: Architectures the pinned instances' prebuilt docker images support.
_SUPPORTED_ARCHS = {"x86_64", "amd64"}

#: Minimum free disk (bytes) the dockerized eval comfortably needs.
_MIN_FREE_BYTES = 120 * 10**9

#: Prompt for the canary session — zero tools, one trivial reply.
_CANARY_PROMPT = "Reply with exactly: OK. Do not use any tools."


def _importable(name: str) -> bool:
    """True when ``name`` can be imported in this interpreter (no side effects)."""
    try:
        return importlib.util.find_spec(name) is not None
    except (ImportError, ValueError):
        return False


def _check_claude() -> tuple[str, bool | None, str]:
    path = shutil.which("claude")
    if not path:
        return ("claude", False, "not found on PATH")
    try:
        proc = subprocess.run(
            ["claude", "--version"], capture_output=True, text=True, timeout=30
        )
    except (OSError, subprocess.TimeoutExpired) as exc:
        return ("claude", False, f"{path} ({exc})")
    if proc.returncode != 0:
        return ("claude", False, f"{path} (--version exited {proc.returncode})")
    version = proc.stdout.strip() or "version unknown"
    return ("claude", True, f"{version} ({path})")


def _check_docker(eval_checks: bool) -> tuple[str, bool | None, str]:
    try:
        proc = subprocess.run(
            ["docker", "info"], capture_output=True, text=True, timeout=60
        )
        reachable = proc.returncode == 0
        why = (proc.stderr or proc.stdout or "").strip().splitlines()
        detail = why[0] if (not reachable and why) else "daemon reachable"
    except (OSError, subprocess.TimeoutExpired) as exc:
        reachable, detail = False, str(exc)
    if reachable:
        return ("docker", True, detail)
    verdict: bool | None = False if eval_checks else None
    return ("docker", verdict, f"not reachable: {detail} (required for evaluate)")


def _check_workspace_ancestry() -> tuple[str, bool | None, str]:
    """No CLAUDE.md or .claude dir anywhere above the workspace root.

    Such entries would be picked up by the CLI's project/local setting
    sources and contaminate every session. The single exception is the
    user-level ``~/.claude`` directory: it is required for subscription auth
    and is excluded from sessions via ``--setting-sources project,local``.
    """
    ws = config.workspace_root()
    user_claude_dir = Path.home() / ".claude"
    findings: list[str] = []
    for parent in [ws, *ws.parents]:
        claude_md = parent / "CLAUDE.md"
        if claude_md.exists():
            findings.append(str(claude_md))
        dot_claude = parent / ".claude"
        if dot_claude.exists() and dot_claude != user_claude_dir:
            findings.append(str(dot_claude))
    if findings:
        return ("workspace_ancestry", False, "found: " + ", ".join(findings))
    return (
        "workspace_ancestry",
        True,
        f"clean above {ws} (user-level ~/.claude exempt)",
    )


def run_checks(*, eval_checks: bool = True) -> list[tuple[str, bool | None, str]]:
    """Run all preflight checks; returns ``(name, verdict, detail)`` tuples.

    ``eval_checks=False`` relaxes evaluation-only requirements (docker) to
    warnings — useful on machines that only run sessions and evaluate
    elsewhere.
    """
    checks: list[tuple[str, bool | None, str]] = []

    checks.append(_check_claude())

    git_path = shutil.which("git")
    checks.append(
        ("git", bool(git_path), git_path or "not found on PATH")
    )

    machine = platform.machine()
    checks.append(
        (
            "arch",
            machine in _SUPPORTED_ARCHS,
            f"{machine} (pinned instances require x86_64)",
        )
    )

    version = ".".join(str(v) for v in tuple(sys.version_info)[:3])
    checks.append(
        ("python", tuple(sys.version_info)[:2] >= (3, 10), f"{version} (need >= 3.10)")
    )

    checks.append(
        (
            "swebench",
            _importable("swebench"),
            "importable" if _importable("swebench") else "not importable (pip install -e .)",
        )
    )

    datasets_ok = _importable("datasets")
    checks.append(
        (
            "datasets",
            True if datasets_ok else None,
            "importable" if datasets_ok else "not importable (needed only for vendor-instances)",
        )
    )

    checks.append(_check_docker(eval_checks))

    try:
        free = shutil.disk_usage(Path.cwd()).free
        disk_ok: bool | None = True if free >= _MIN_FREE_BYTES else None
        detail = f"{free / 10**9:.0f} GB free (evaluate needs ~120 GB)"
    except OSError as exc:
        disk_ok, detail = None, f"disk_usage failed: {exc}"
    checks.append(("disk", disk_ok, detail))

    checks.append(_check_workspace_ancestry())

    if os.environ.get("ANTHROPIC_API_KEY"):
        checks.append(
            (
                "anthropic_api_key",
                None,
                "set (scrubbed from sessions, but unset it to be safe)",
            )
        )
    else:
        checks.append(("anthropic_api_key", True, "not set"))

    return checks


def run_canary(
    *, model: str = config.CANARY_MODEL, claude_bin: str = "claude"
) -> dict:
    """Run one cheap real session with the pinned flags and audit its transcript.

    A throwaway workspace keeps the canary hermetic; ``max_turns=2`` caps the
    spend. Returns::

        {"result_ok": bool,        # the session itself succeeded
         "error":     str | None,  # runner error when it did not
         "session_id": str,        # pre-generated uuid4
         "audit":     dict | None, # audit_transcript() output, None if no transcript
         "clean":     bool}        # ok session + clean audit + zero marker warnings

    ``clean`` is the machine's session-cleanliness verdict: anything less
    means benchmark sessions on this host would be contaminated.
    """
    session_id = str(uuid.uuid4())
    with tempfile.TemporaryDirectory(prefix="fvk_canary_") as tmp:
        ws = Path(tmp)
        (ws / ".fvk_bench").mkdir()
        result = claude_runner.run_arm_session(
            ws,
            "baseline",
            _CANARY_PROMPT,
            session_id=session_id,
            timeout=300,
            claude_bin=claude_bin,
            model=model,
            max_turns=2,
        )
        audit = None
        transcript = claude_runner.transcript_path(ws, session_id)
        if transcript is not None:
            audit = claude_runner.audit_transcript(transcript)
    clean = bool(
        result.ok
        and audit is not None
        and audit["ok"]
        and not audit["marker_warnings"]
    )
    return {
        "result_ok": result.ok,
        "error": result.error,
        "session_id": session_id,
        "audit": audit,
        "clean": clean,
    }

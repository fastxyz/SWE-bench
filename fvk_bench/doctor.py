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

from fvk_bench import claude_runner, codex_runner, config

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


def _check_claude(claude_bin: str = "claude") -> tuple[str, bool | None, str]:
    path = shutil.which(claude_bin)
    if not path:
        return ("claude", False, "not found on PATH")
    try:
        proc = subprocess.run(
            [path, "--version"], capture_output=True, text=True, timeout=30
        )
    except (OSError, subprocess.TimeoutExpired) as exc:
        return ("claude", False, f"{path} ({exc})")
    if proc.returncode != 0:
        return ("claude", False, f"{path} (--version exited {proc.returncode})")
    version = proc.stdout.strip() or "version unknown"
    # `claude --version` prints e.g. "2.1.169 (Claude Code)"; the leading
    # token is the version proper. Any version other than the one this infra
    # was validated against is suspicious but not blocking → warn.
    leading = version.split()[0]
    if leading != config.TESTED_CLAUDE_VERSION:
        return (
            "claude",
            None,
            f"untested version {leading}"
            f" (validated against {config.TESTED_CLAUDE_VERSION})",
        )
    return ("claude", True, f"{version} ({path})")


def _codex_version_token(output: str) -> str:
    parts = output.strip().split()
    if len(parts) >= 2 and parts[0] == "codex-cli":
        return parts[1]
    return parts[0] if parts else "version unknown"


def _check_codex(codex_bin: str = "codex") -> tuple[str, bool | None, str]:
    path = shutil.which(codex_bin)
    if not path:
        return ("codex", False, "not found on PATH")
    try:
        proc = subprocess.run(
            [path, "--version"], capture_output=True, text=True, timeout=30
        )
    except (OSError, subprocess.TimeoutExpired) as exc:
        return ("codex", False, f"{path} ({exc})")
    if proc.returncode != 0:
        return ("codex", False, f"{path} (--version exited {proc.returncode})")
    version = proc.stdout.strip() or "version unknown"
    leading = _codex_version_token(version)
    if leading != config.TESTED_CODEX_VERSION:
        return (
            "codex",
            None,
            f"untested version {leading}"
            f" (validated against {config.TESTED_CODEX_VERSION})",
        )
    return ("codex", True, f"{version} ({path})")


def _check_codex_auth(codex_bin: str = "codex") -> tuple[str, bool | None, str]:
    path = shutil.which(codex_bin)
    if not path:
        return ("codex_auth", False, "codex not found")
    try:
        proc = subprocess.run(
            [path, "login", "status"], capture_output=True, text=True, timeout=30
        )
    except (OSError, subprocess.TimeoutExpired) as exc:
        return ("codex_auth", False, str(exc))
    detail = (proc.stdout or proc.stderr or "").strip() or "no login status output"
    if proc.returncode != 0:
        return ("codex_auth", False, f"{detail} (exit {proc.returncode})")
    if "Logged in using ChatGPT" not in detail:
        return (
            "codex_auth",
            False,
            f"{detail} (need ChatGPT/Codex subscription auth)",
        )
    return ("codex_auth", True, "Logged in using ChatGPT")


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


def run_checks(
    *,
    eval_checks: bool = True,
    agent: str = config.DEFAULT_AGENT,
    claude_bin: str = "claude",
    codex_bin: str = "codex",
) -> list[tuple[str, bool | None, str]]:
    """Run all preflight checks; returns ``(name, verdict, detail)`` tuples.

    ``eval_checks=False`` relaxes evaluation-only requirements (docker) to
    warnings — useful on machines that only run sessions and evaluate
    elsewhere.
    """
    checks: list[tuple[str, bool | None, str]] = []

    if agent == "codex":
        checks.append(_check_codex(codex_bin))
        checks.append(_check_codex_auth(codex_bin))
    else:
        checks.append(_check_claude(claude_bin))

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


def run_codex_canary(
    *, model: str = config.CODEX_MODEL, codex_bin: str = "codex"
) -> dict:
    """Run one real Codex session with the pinned Codex production flags.

    Unlike Claude, Codex has no separate cheap canary model for this benchmark:
    the important preflight is proving subscription access to the pinned
    ``gpt-5.5`` model under ``--ignore-user-config``.
    """
    runner = codex_runner.CodexRunner(codex_bin=codex_bin, model=model)
    with tempfile.TemporaryDirectory(prefix="fvk_codex_canary_") as tmp:
        ws = Path(tmp)
        (ws / ".fvk_bench").mkdir()
        result = runner.run_fresh(
            ws,
            "baseline",
            _CANARY_PROMPT,
            timeout=300,
        )
        audit = None
        if result.session_id:
            transcript = runner.transcript_path(ws, result.session_id)
            if transcript is not None:
                audit = runner.audit_transcript(transcript)
    clean = bool(
        result.ok
        and audit is not None
        and audit["ok"]
        and not audit["exec_warnings"]
        and not audit["tool_uses"]
    )
    return {
        "result_ok": result.ok,
        "error": result.error,
        "session_id": result.session_id,
        "audit": audit,
        "clean": clean,
    }

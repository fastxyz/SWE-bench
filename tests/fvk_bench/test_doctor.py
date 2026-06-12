"""Tests for fvk_bench.doctor — written before implementation (TDD).

``run_checks`` is driven entirely through monkeypatched probes (shutil.which,
subprocess.run, platform.machine, sys.version_info, importability, disk) so
the verdict logic is tested without touching the host. The canary tests reuse
the fake-claude wrapper pattern from test_arms.py: an edits script (executed
inside the fake) writes a transcript into the munged ``~/.claude/projects``
location the real CLI would use, with HOME monkeypatched to a temp dir.
"""

import json
import sys
import uuid
from pathlib import Path
from types import SimpleNamespace

import pytest

import fvk_bench.doctor as doctor
from fvk_bench import config

# ---------------------------------------------------------------------------
# run_checks
# ---------------------------------------------------------------------------

EXPECTED_CHECK_NAMES = [
    "claude",
    "git",
    "arch",
    "python",
    "swebench",
    "datasets",
    "docker",
    "disk",
    "workspace_ancestry",
    "anthropic_api_key",
]


@pytest.fixture()
def healthy_host(monkeypatch, tmp_path):
    """Monkeypatch every probe to a healthy x86_64 host with all deps."""
    monkeypatch.setattr(doctor.shutil, "which", lambda name: f"/usr/bin/{name}")

    def fake_run(argv, **kwargs):
        if argv[0] == "docker":
            return SimpleNamespace(returncode=0, stdout="docker info ok\n", stderr="")
        return SimpleNamespace(returncode=0, stdout="2.1.169 (Claude Code)\n", stderr="")

    monkeypatch.setattr(doctor.subprocess, "run", fake_run)
    monkeypatch.setattr(doctor.platform, "machine", lambda: "x86_64")
    monkeypatch.setattr(doctor, "_importable", lambda name: True)
    monkeypatch.setattr(
        doctor.shutil,
        "disk_usage",
        lambda p: SimpleNamespace(total=10**12, used=0, free=200 * 10**9),
    )
    home = tmp_path / "home"
    (home / ".claude").mkdir(parents=True)  # user-level dir: required for auth
    monkeypatch.setenv("HOME", str(home))
    monkeypatch.setenv("FVK_BENCH_WORKSPACE", str(home / "runs"))
    monkeypatch.delenv("ANTHROPIC_API_KEY", raising=False)
    return home


def test_run_checks_all_ok(healthy_host):
    checks = doctor.run_checks()

    assert [name for name, _, _ in checks] == EXPECTED_CHECK_NAMES
    by_name = {name: (ok, detail) for name, ok, detail in checks}
    for name in EXPECTED_CHECK_NAMES:
        assert by_name[name][0] is True, f"{name}: {by_name[name]}"
    assert "2.1.169" in by_name["claude"][1]
    assert "x86_64" in by_name["arch"][1]
    # The user-level ~/.claude in the workspace ancestry is NOT a violation
    # (it is required for subscription auth and excluded via setting-sources).


def test_run_checks_failures(monkeypatch, healthy_host):
    monkeypatch.setattr(
        doctor.shutil,
        "which",
        lambda name: None if name == "claude" else f"/usr/bin/{name}",
    )
    monkeypatch.setattr(doctor.platform, "machine", lambda: "arm64")
    monkeypatch.setattr(doctor.sys, "version_info", (3, 9, 5))
    monkeypatch.setattr(doctor, "_importable", lambda name: name != "swebench")

    by_name = {name: ok for name, ok, _ in doctor.run_checks()}

    assert by_name["claude"] is False
    assert by_name["arch"] is False
    assert by_name["python"] is False
    assert by_name["swebench"] is False
    assert by_name["datasets"] is True  # still importable


def test_run_checks_warn_only_checks(monkeypatch, healthy_host):
    def docker_down(argv, **kwargs):
        if argv[0] == "docker":
            return SimpleNamespace(returncode=1, stdout="", stderr="no daemon")
        return SimpleNamespace(returncode=0, stdout="2.1.169\n", stderr="")

    monkeypatch.setattr(doctor.subprocess, "run", docker_down)
    monkeypatch.setattr(
        doctor.shutil,
        "disk_usage",
        lambda p: SimpleNamespace(total=10**12, used=0, free=50 * 10**9),
    )
    monkeypatch.setattr(doctor, "_importable", lambda name: name != "datasets")
    monkeypatch.setenv("ANTHROPIC_API_KEY", "sk-test")

    by_name = {name: ok for name, ok, _ in doctor.run_checks()}
    assert by_name["docker"] is False  # eval_checks=True → hard fail

    by_name = {name: ok for name, ok, _ in doctor.run_checks(eval_checks=False)}
    assert by_name["docker"] is None  # warn-only without eval
    assert by_name["disk"] is None  # <120GB is always warn-only
    assert by_name["datasets"] is None  # warn-only
    assert by_name["anthropic_api_key"] is None  # scrubbed anyway → warn


def test_run_checks_workspace_ancestry_contamination(monkeypatch, healthy_host):
    home = healthy_host
    ws_root = home / "projects" / "bench-runs"
    monkeypatch.setenv("FVK_BENCH_WORKSPACE", str(ws_root))
    (home / "projects").mkdir(parents=True)
    (home / "projects" / "CLAUDE.md").write_text("memory\n", encoding="utf-8")
    (home / "projects" / ".claude").mkdir()

    by_name = {name: (ok, detail) for name, ok, detail in doctor.run_checks()}

    ok, detail = by_name["workspace_ancestry"]
    assert ok is False
    assert "CLAUDE.md" in detail and ".claude" in detail


# ---------------------------------------------------------------------------
# run_canary
# ---------------------------------------------------------------------------

# Edits script executed inside the fake claude (cwd = canary workspace): it
# writes a transcript where the real CLI would (HOME is monkeypatched), plus
# the received argv to $HOME/canary_argv.json so the test can golden-check the
# invocation. {LINES} is replaced with the transcript's JSON lines.
_TRANSCRIPT_EDITS = """
import json, os, re, sys

sid = sys.argv[sys.argv.index("--session-id") + 1]
munged = re.sub(r"[^A-Za-z0-9-]", "-", os.getcwd())
proj = os.path.join(os.environ["HOME"], ".claude", "projects", munged)
os.makedirs(proj, exist_ok=True)
with open(os.path.join(proj, sid + ".jsonl"), "w", encoding="utf-8") as fh:
    fh.write({LINES!r})
with open(os.path.join(os.environ["HOME"], "canary_argv.json"), "w", encoding="utf-8") as fh:
    json.dump(sys.argv, fh)
"""

_CLEAN_LINE = json.dumps(
    {"type": "assistant", "message": {"content": [{"type": "text", "text": "OK"}]}}
)
_DIRTY_LINE = json.dumps(
    {
        "type": "assistant",
        "message": {"content": [{"type": "tool_use", "name": "Bash", "input": {}}]},
    }
)


def _canary_bin(tmp_path: Path, fake_claude_bin: Path, transcript_lines: str | None) -> Path:
    """Wrap the fake claude; optionally have it write a transcript via edits."""
    wrapper = tmp_path / "canary_bin" / "claude"
    wrapper.parent.mkdir(parents=True, exist_ok=True)
    lines = ["#!/bin/sh"]
    if transcript_lines is not None:
        edits = tmp_path / "canary_edits.py"
        edits.write_text(
            _TRANSCRIPT_EDITS.replace("{LINES!r}", repr(transcript_lines)),
            encoding="utf-8",
        )
        lines.append(f'export FAKE_CLAUDE_EDITS="{edits}"')
    lines.append(f'exec "{fake_claude_bin}" "$@"')
    wrapper.write_text("\n".join(lines) + "\n", encoding="utf-8")
    wrapper.chmod(0o755)
    return wrapper


@pytest.fixture()
def canary_home(tmp_path, monkeypatch) -> Path:
    home = tmp_path / "home"
    home.mkdir()
    monkeypatch.setenv("HOME", str(home))  # Path.home() and the child env
    return home


def test_run_canary_clean(tmp_path, fake_claude_bin, canary_home):
    bin_path = _canary_bin(tmp_path, fake_claude_bin, _CLEAN_LINE + "\n")

    res = doctor.run_canary(claude_bin=str(bin_path))

    assert res["result_ok"] is True
    assert res["clean"] is True
    assert res["audit"]["ok"] is True
    assert res["audit"]["violations"] == []
    assert res["audit"]["marker_warnings"] == []
    assert uuid.UUID(res["session_id"]).version == 4

    # Golden invocation facts: canary model, 2-turn cap, fresh session id.
    argv = json.loads((canary_home / "canary_argv.json").read_text(encoding="utf-8"))
    assert argv[argv.index("--model") + 1] == config.CANARY_MODEL
    assert argv[argv.index("--max-turns") + 1] == "2"
    assert argv[argv.index("--session-id") + 1] == res["session_id"]


def test_run_canary_dirty_tool_use(tmp_path, fake_claude_bin, canary_home):
    bin_path = _canary_bin(tmp_path, fake_claude_bin, _DIRTY_LINE + "\n")

    res = doctor.run_canary(claude_bin=str(bin_path))

    assert res["result_ok"] is True
    assert res["clean"] is False
    assert res["audit"]["ok"] is False
    assert res["audit"]["violations"] == ["Bash"]


def test_run_canary_marker_warning_is_dirty(tmp_path, fake_claude_bin, canary_home):
    marker_line = json.dumps(
        {"type": "user", "message": {"content": "server mcp__gh attached"}}
    )
    bin_path = _canary_bin(
        tmp_path, fake_claude_bin, _CLEAN_LINE + "\n" + marker_line + "\n"
    )

    res = doctor.run_canary(claude_bin=str(bin_path))

    assert res["audit"]["ok"] is True  # markers do not flip the audit verdict
    assert res["audit"]["marker_warnings"] == [2]
    assert res["clean"] is False  # ...but they DO dirty the canary


def test_run_canary_missing_transcript(tmp_path, fake_claude_bin, canary_home):
    bin_path = _canary_bin(tmp_path, fake_claude_bin, None)  # no transcript written

    res = doctor.run_canary(claude_bin=str(bin_path))

    assert res["result_ok"] is True
    assert res["audit"] is None
    assert res["clean"] is False


def test_run_canary_session_failure(tmp_path, canary_home):
    res = doctor.run_canary(claude_bin="/nonexistent/claude")

    assert res["result_ok"] is False
    assert res["clean"] is False
    assert res["audit"] is None

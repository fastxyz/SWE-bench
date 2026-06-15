"""Tests for fvk_bench.codex_runner and the runner factory — pure logic only.

The real ``codex`` CLI is never invoked here (running it needs a Codex
subscription and a live model). These tests pin the invocation contract
(``build_argv`` golden lists), the rollout-schema audit, transcript lookup, and
``get_runner`` dispatch — everything that can be checked without a session.
``CODEX_HOME`` is redirected to a tmp dir so transcript lookups never touch a
real ``~/.codex``.
"""

import json
from pathlib import Path

import pytest

import fvk_bench.codex_runner as codex_runner
from fvk_bench import config
from fvk_bench.runner import get_runner

PROMPT = "Fix the bug described in benchmark/PROBLEM.md."
SID = "019e4af4-7e27-7d52-a643-ed8778933466"


# ---------------------------------------------------------------------------
# 1. build_argv golden lists (the pinned codex invocation contract)
# ---------------------------------------------------------------------------

def _shared_opts() -> list[str]:
    return [
        "-m", config.CODEX_MODEL,
        "-c", f"model_reasoning_effort={config.CODEX_EFFORT}",
        "--sandbox", config.CODEX_SANDBOX,
        "--skip-git-repo-check",
        "--ignore-user-config",
        "--json",
    ]


def test_build_argv_fresh_golden():
    argv = codex_runner.build_argv(
        PROMPT, "baseline", cwd=Path("/ws"), last_message_file=Path("/ws/last.txt")
    )
    assert argv == (
        ["codex", "exec", PROMPT]
        + _shared_opts()
        + ["-C", "/ws", "-o", "/ws/last.txt"]
    )


def test_build_argv_fork_resume_golden():
    argv = codex_runner.build_argv(
        PROMPT, "fvk", resume_id=SID, cwd=Path("/ws"), last_message_file=Path("/ws/last.txt")
    )
    assert argv == (
        ["codex", "exec"]
        + _shared_opts()
        + ["-C", "/ws", "-o", "/ws/last.txt"]
        + ["resume", SID, PROMPT]
    )


def test_build_argv_fork_parent_options_precede_resume_subcommand():
    argv = codex_runner.build_argv(
        PROMPT, "fvk", resume_id=SID, cwd=Path("/ws"), last_message_file=Path("/ws/last.txt")
    )
    resume_index = argv.index("resume")

    assert "--sandbox" in argv[:resume_index]
    assert "-C" in argv[:resume_index]
    assert "-o" in argv[:resume_index]
    assert "--sandbox" not in argv[resume_index:]
    assert "-C" not in argv[resume_index:]
    assert "-o" not in argv[resume_index:]


def test_build_argv_overrides_bin_and_model():
    argv = codex_runner.build_argv(
        PROMPT, "control", codex_bin="/opt/codex", model="gpt-x", effort="high"
    )
    assert argv[0] == "/opt/codex"
    assert argv[argv.index("-m") + 1] == "gpt-x"
    assert "model_reasoning_effort=high" in argv


# ---------------------------------------------------------------------------
# 2. audit_transcript: rollout-schema census, MCP/plugin violations (hard),
#    test-execution warnings (soft), unparseable lines tolerated
# ---------------------------------------------------------------------------

def _shell_call(command: str) -> str:
    return json.dumps(
        {"type": "response_item", "payload": {"type": "local_shell_call", "command": command}}
    )


def _fn_call(name: str) -> str:
    return json.dumps(
        {"type": "response_item", "payload": {"type": "function_call", "name": name}}
    )


def test_audit_flags_mcp_violation_and_exec_warning(tmp_path):
    lines = [
        json.dumps({"type": "session_meta", "payload": {"id": SID}}),
        _shell_call("rg --files repo/"),               # benign read via shell
        _shell_call("python -m pytest tests/foo.py"),  # forbidden execution -> warning
        _fn_call("mcp__github__search"),               # config leak -> violation
        "{not valid json",                             # unparseable
    ]
    path = tmp_path / "rollout.jsonl"
    path.write_text("\n".join(lines) + "\n", encoding="utf-8")

    audit = codex_runner.CodexRunner().audit_transcript(path)

    assert audit["ok"] is False                        # MCP tool flips ok
    assert audit["violations"] == ["mcp__github__search"]
    assert any("pytest" in w for w in audit["exec_warnings"])
    assert audit["tool_uses"]["local_shell_call"] == 2
    assert audit["unparseable_lines"] == 1


def test_audit_clean_session_ok(tmp_path):
    lines = [
        json.dumps({"type": "session_meta", "payload": {"id": SID}}),
        _shell_call("sed -n '1,40p' repo/lib.py"),
        _fn_call("apply_patch"),
        json.dumps({"type": "event_msg", "payload": {"type": "task_complete"}}),
    ]
    path = tmp_path / "rollout.jsonl"
    path.write_text("\n".join(lines) + "\n", encoding="utf-8")

    audit = codex_runner.CodexRunner().audit_transcript(path)

    assert audit["ok"] is True
    assert audit["violations"] == []
    assert audit["exec_warnings"] == []


# ---------------------------------------------------------------------------
# 3. transcript_path: saved per-session copy preferred; None when absent
# ---------------------------------------------------------------------------

def test_transcript_path_prefers_saved_copy(tmp_path, monkeypatch):
    monkeypatch.setenv("CODEX_HOME", str(tmp_path / "codex_home"))  # no real ~/.codex
    ws = tmp_path / "ws"
    saved = ws / ".fvk_bench" / "codex" / f"{SID}.rollout.jsonl"
    saved.parent.mkdir(parents=True)
    saved.write_text("{}\n", encoding="utf-8")

    runner = codex_runner.CodexRunner()
    assert runner.transcript_path(ws, SID) == saved
    assert runner.transcript_path(ws, "missing-sid") is None
    assert runner.transcript_path(ws, "") is None


def test_result_prefers_stdout_thread_id_over_newest_rollout(tmp_path, monkeypatch):
    """Parallel Codex runs can finish close together; stdout owns the session id."""
    home = tmp_path / "codex_home"
    sessions = home / "sessions" / "2026" / "06" / "15"
    sessions.mkdir(parents=True)
    sid_a = "019ecb60-1e74-7960-8575-83474e101605"
    sid_b = "019ecb60-1e7c-7a62-a3c5-97f11d421c7d"
    rollout_a = sessions / f"rollout-2026-06-15T13-02-14-{sid_a}.jsonl"
    rollout_b = sessions / f"rollout-2026-06-15T13-02-14-{sid_b}.jsonl"
    rollout_a.write_text(
        json.dumps({"type": "session_meta", "payload": {"id": sid_a}}) + "\n",
        encoding="utf-8",
    )
    rollout_b.write_text(
        json.dumps({"type": "session_meta", "payload": {"id": sid_b}}) + "\n",
        encoding="utf-8",
    )
    # Make B newest to reproduce the old race-prone discovery behavior.
    rollout_a.touch()
    rollout_b.touch()
    monkeypatch.setenv("CODEX_HOME", str(home))

    ws = tmp_path / "ws"
    ws.mkdir()
    stdout = "\n".join([
        json.dumps({"type": "thread.started", "thread_id": sid_a}),
        json.dumps({"type": "turn.started"}),
        json.dumps({"type": "turn.completed"}),
    ])

    result = codex_runner.CodexRunner()._result(
        ws, "baseline", stdout, "", 0, False, 1.0, None
    )

    assert result.session_id == sid_a
    saved = ws / ".fvk_bench" / "codex" / f"{sid_a}.rollout.jsonl"
    assert saved.read_text(encoding="utf-8") == rollout_a.read_text(encoding="utf-8")
    assert not (ws / ".fvk_bench" / "codex" / f"{sid_b}.rollout.jsonl").exists()


# ---------------------------------------------------------------------------
# 4. get_runner dispatch
# ---------------------------------------------------------------------------

def test_get_runner_dispatch():
    from fvk_bench.claude_runner import ClaudeRunner

    assert isinstance(get_runner("claude"), ClaudeRunner)
    assert get_runner("claude").name == "claude"
    assert isinstance(get_runner("codex"), codex_runner.CodexRunner)
    assert get_runner("codex").name == "codex"
    assert get_runner("codex", model="gpt-x")._model == "gpt-x"
    with pytest.raises(ValueError):
        get_runner("gemini")

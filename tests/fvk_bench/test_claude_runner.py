"""Tests for fvk_bench.claude_runner — written before implementation (TDD).

The real `claude` CLI is never invoked: ``fake_claude_bin`` (conftest) installs
tests/fvk_bench/fixtures/fake_claude.py as an executable ``claude``. Scenario
selection is via the ``FAKE_CLAUDE_SCENARIO`` env var, which the runner's
scrubbed environment deliberately drops — so scenario tests wrap the fake in a
tiny shell script that injects the variable *inside* the child. That keeps the
library's env scrubbing fully exercised (nothing is monkeypatched around it).
"""

import json
from pathlib import Path

import pytest

import fvk_bench.claude_runner as claude_runner
from fvk_bench import config

SID = "11111111-1111-1111-1111-111111111111"
PROMPT = "Fix the bug described in benchmark/PROBLEM.md."


def _scenario_bin(tmp_path: Path, fake_claude_bin: Path, scenario: str) -> Path:
    """Wrap the fake claude so FAKE_CLAUDE_SCENARIO survives the env scrub."""
    wrapper = tmp_path / "scenario_bin" / "claude"
    wrapper.parent.mkdir(parents=True, exist_ok=True)
    wrapper.write_text(
        f'#!/bin/sh\nFAKE_CLAUDE_SCENARIO={scenario} exec "{fake_claude_bin}" "$@"\n',
        encoding="utf-8",
    )
    wrapper.chmod(0o755)
    return wrapper


# ---------------------------------------------------------------------------
# 1. build_argv golden lists (the pinned invocation contract, verbatim)
# ---------------------------------------------------------------------------

def _common_argv(prompt: str, arm: str, claude_bin: str = "claude") -> list:
    return [
        claude_bin, "-p", prompt,
        "--model", config.MODEL,
        "--effort", config.EFFORT,
        "--max-turns", str(config.MAX_TURNS[arm]),
        "--output-format", "json",
        "--permission-mode", config.PERMISSION_MODE,
        "--setting-sources", config.SETTING_SOURCES,
        "--disable-slash-commands",
        "--tools", config.TOOLS,
        "--strict-mcp-config", "--mcp-config", '{"mcpServers":{}}',
    ]


def test_build_argv_fresh_golden():
    argv = claude_runner.build_argv(PROMPT, "baseline", session_id=SID)
    assert argv == _common_argv(PROMPT, "baseline") + ["--session-id", SID]


def test_build_argv_fork_golden():
    argv = claude_runner.build_argv(PROMPT, "fvk", resume_id=SID)
    assert argv == _common_argv(PROMPT, "fvk") + ["--resume", SID, "--fork-session"]


def test_build_argv_overrides():
    argv = claude_runner.build_argv(
        PROMPT, "control",
        session_id=SID, claude_bin="/opt/claude", model="claude-x", max_turns=3,
    )
    assert argv[0] == "/opt/claude"
    assert argv[argv.index("--model") + 1] == "claude-x"
    assert argv[argv.index("--max-turns") + 1] == "3"


# ---------------------------------------------------------------------------
# 2. exactly one of session_id / resume_id
# ---------------------------------------------------------------------------

def test_build_argv_requires_exactly_one_session_arg():
    with pytest.raises(ValueError):
        claude_runner.build_argv(PROMPT, "baseline")
    with pytest.raises(ValueError):
        claude_runner.build_argv(PROMPT, "baseline", session_id=SID, resume_id=SID)


# ---------------------------------------------------------------------------
# 3. happy path: prompt file, argv, cwd, scrubbed env, raw capture, envelope
# ---------------------------------------------------------------------------

def test_run_ok_captures_everything(tmp_path, fake_claude_bin, monkeypatch):
    # Plant leaky variables that the runner MUST NOT pass to the session.
    monkeypatch.setenv("ANTHROPIC_API_KEY", "leak")
    monkeypatch.setenv("CLAUDE_FOO", "leak")

    ws = tmp_path / "ws"
    ws.mkdir()

    result = claude_runner.run_arm_session(
        ws, "baseline", PROMPT, session_id=SID, claude_bin=str(fake_claude_bin)
    )

    assert result.ok is True
    assert result.error is None
    assert result.session_id == SID  # --session-id value echoed back
    assert result.num_turns == 7
    assert result.subtype == "success"
    assert result.duration_seconds > 0

    # Prompt file is the artifact of record.
    prompt_file = ws / ".fvk_bench" / "prompts" / "baseline.md"
    assert prompt_file.read_text(encoding="utf-8") == PROMPT

    # The fake captured exactly what the runner passed.
    capture = json.loads((ws / "fake_claude_capture.json").read_text(encoding="utf-8"))
    assert capture["cwd"] == str(ws)
    assert capture["argv"][1:] == claude_runner.build_argv(
        PROMPT, "baseline", session_id=SID, claude_bin=str(fake_claude_bin)
    )[1:]

    env = capture["env"]
    leaked = [k for k in env if k.startswith("ANTHROPIC_") or k.startswith("CLAUDE_")]
    assert leaked == []
    assert env["TERM"] == "dumb"
    assert env["LANG"] == "C.UTF-8"
    assert env["TZ"] == "UTC"

    # Raw stdout envelope saved verbatim; stderr saved too.
    raw_stdout = ws / ".fvk_bench" / "raw" / "baseline.stdout.json"
    assert json.loads(raw_stdout.read_text(encoding="utf-8")) == result.raw_json
    assert result.raw_json["session_id"] == SID
    assert (ws / ".fvk_bench" / "raw" / "baseline.stderr.txt").exists()

    # Exactly one invocation, marker logged.
    log = (ws / "fake_claude_invocations.log").read_text(encoding="utf-8")
    assert log.count("FAKE_CLAUDE_INVOKED") == 1


# ---------------------------------------------------------------------------
# 4. timeout kills the whole process group, quickly
# ---------------------------------------------------------------------------

def test_run_timeout_kills(tmp_path, fake_claude_bin):
    slow_bin = _scenario_bin(tmp_path, fake_claude_bin, "slow")
    ws = tmp_path / "ws"
    ws.mkdir()

    result = claude_runner.run_arm_session(
        ws, "baseline", PROMPT, session_id=SID, timeout=2, claude_bin=str(slow_bin)
    )

    assert result.ok is False
    assert result.error == "timeout"
    assert result.duration_seconds < 15  # killed, not waited out (fake sleeps 30s)
    # Raw files are written even on timeout; the fake did start.
    assert (ws / ".fvk_bench" / "raw" / "baseline.stdout.json").exists()
    assert (ws / "fake_claude_invocations.log").exists()


# ---------------------------------------------------------------------------
# 5. unparseable stdout
# ---------------------------------------------------------------------------

def test_run_bad_json(tmp_path, fake_claude_bin):
    bad_bin = _scenario_bin(tmp_path, fake_claude_bin, "badjson")
    ws = tmp_path / "ws"
    ws.mkdir()

    result = claude_runner.run_arm_session(
        ws, "baseline", PROMPT, session_id=SID, claude_bin=str(bad_bin)
    )

    assert result.ok is False
    assert result.error == "bad_json"
    assert result.raw_json is None
    assert result.session_id is None
    raw = ws / ".fvk_bench" / "raw" / "baseline.stdout.json"
    assert "this is not json" in raw.read_text(encoding="utf-8")


# ---------------------------------------------------------------------------
# 6. nonzero exit: error recorded, stdout still parsed for forensics
# ---------------------------------------------------------------------------

def test_run_nonzero_exit(tmp_path, fake_claude_bin):
    exit2_bin = _scenario_bin(tmp_path, fake_claude_bin, "exit2")
    ws = tmp_path / "ws"
    ws.mkdir()

    result = claude_runner.run_arm_session(
        ws, "baseline", PROMPT, session_id=SID, claude_bin=str(exit2_bin)
    )

    assert result.ok is False
    assert result.error == "nonzero_exit:2"
    # Forensics: the error envelope was still parsed.
    assert result.subtype == "error"
    assert result.raw_json == {"type": "result", "subtype": "error", "is_error": True}
    assert result.session_id is None
    stderr = ws / ".fvk_bench" / "raw" / "baseline.stderr.txt"
    assert "boom" in stderr.read_text(encoding="utf-8")


# ---------------------------------------------------------------------------
# 7. path munging (cwd -> ~/.claude/projects dir name)
# ---------------------------------------------------------------------------

def test_munge():
    assert claude_runner._munge("/home/xc/Pro jects_x.y/ws") == "-home-xc-Pro-jects-x-y-ws"


# ---------------------------------------------------------------------------
# 8. transcript_path: primary munged location, glob fallback, then None
# ---------------------------------------------------------------------------

def test_transcript_path_fallback(tmp_path, monkeypatch):
    tmp_home = tmp_path / "home"
    monkeypatch.setattr(Path, "home", classmethod(lambda cls: tmp_home))

    ws = tmp_path / "ws dir"  # space exercises munging in the primary path
    ws.mkdir()
    projects = tmp_home / ".claude" / "projects"

    # Primary hit: file under the munged-cwd directory.
    primary_dir = projects / claude_runner._munge(str(ws.resolve()))
    primary_dir.mkdir(parents=True)
    primary = primary_dir / f"{SID}.jsonl"
    primary.write_text("{}\n", encoding="utf-8")
    assert claude_runner.transcript_path(ws, SID) == primary

    # Fallback hit: munged dir name differs, glob across projects finds it.
    sid2 = "22222222-2222-2222-2222-222222222222"
    other_dir = projects / "-some-other-munged-cwd"
    other_dir.mkdir(parents=True)
    fallback = other_dir / f"{sid2}.jsonl"
    fallback.write_text("{}\n", encoding="utf-8")
    assert claude_runner.transcript_path(ws, sid2) == fallback

    # Absent everywhere: None.
    assert claude_runner.transcript_path(ws, "33333333-3333-3333-3333-333333333333") is None


# ---------------------------------------------------------------------------
# 9. audit_transcript: tool census, violations, markers, unparseable lines
# ---------------------------------------------------------------------------

def _assistant_line(*tool_names: str) -> str:
    content = [{"type": "text", "text": "thinking..."}]
    content += [{"type": "tool_use", "name": n, "input": {}} for n in tool_names]
    return json.dumps({"type": "assistant", "message": {"content": content}})


def test_audit_transcript_flags_dirty_session(tmp_path):
    lines = [
        _assistant_line("Read"),                                          # 1
        _assistant_line("Bash"),                                          # 2  violation
        json.dumps({"type": "user", "message": {"content": "go on"}}),    # 3
        json.dumps({"type": "system", "text": "server mcp__gh attached"}),# 4  marker
        "{this line is not json",                                         # 5  unparseable
        _assistant_line("Glob"),                                          # 6
    ]
    path = tmp_path / "session.jsonl"
    path.write_text("\n".join(lines) + "\n", encoding="utf-8")

    audit = claude_runner.audit_transcript(path)

    assert audit == {
        "ok": False,
        "tool_uses": {"Read": 1, "Bash": 1, "Glob": 1},
        "violations": ["Bash"],
        "marker_warnings": [4],
        "unparseable_lines": 1,
        "lines": 6,
    }


def test_audit_transcript_clean_session(tmp_path):
    lines = [
        _assistant_line("Read", "Grep"),
        json.dumps({"type": "user", "message": {"content": "ok"}}),
        _assistant_line("Edit"),
    ]
    path = tmp_path / "session.jsonl"
    path.write_text("\n".join(lines) + "\n", encoding="utf-8")

    audit = claude_runner.audit_transcript(path)

    assert audit["ok"] is True
    assert audit["violations"] == []
    assert audit["marker_warnings"] == []
    assert audit["unparseable_lines"] == 0
    assert audit["tool_uses"] == {"Read": 1, "Grep": 1, "Edit": 1}
    assert audit["lines"] == 3


def test_audit_transcript_flags_all_marker_strings(tmp_path):
    lines = [
        json.dumps({"type": "user", "message": {"content": "Available agent types: x"}}),
        json.dumps({"type": "user", "message": {"content": "clean line"}}),
        json.dumps({"type": "user", "message": {"content": "see <functions> block"}}),
    ]
    path = tmp_path / "session.jsonl"
    path.write_text("\n".join(lines) + "\n", encoding="utf-8")

    audit = claude_runner.audit_transcript(path)

    assert audit["marker_warnings"] == [1, 3]
    assert audit["ok"] is True  # markers warn; only tool violations flip ok

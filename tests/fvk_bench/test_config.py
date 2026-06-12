import os
from pathlib import Path
from fvk_bench import config

def test_pinned_invocation_constants():
    assert config.MODEL == "claude-opus-4-8"
    assert config.EFFORT == "max"
    assert config.MAX_TURNS == {"baseline": 200, "fvk": 200, "control": 200}
    assert config.MAX_TURNS["fvk"] == config.MAX_TURNS["control"]  # control validity
    assert config.TOOLS == "Read,Write,Edit,Glob,Grep"
    assert config.ARMS == ("baseline", "fvk", "control")
    assert config.ARM_TIMEOUT_SECONDS == 4 * 3600
    assert config.DATASET_NAME == "princeton-nlp/SWE-bench_Verified"

def test_tested_claude_version_pinned():
    # The version this infra was validated against; doctor warns on mismatch.
    assert config.TESTED_CLAUDE_VERSION == "2.1.169"

def test_fvk_materials_copy_set():
    assert config.FVK_MATERIALS_FILES == (
        "README.md", "AGENTS.md", "commands/formalize.md", "commands/verify.md",
        "knowledge/k-framework.md", "knowledge/matching-logic.md",
        "knowledge/reachability-and-circularities.md", "knowledge/sources.md",
    )

def test_workspace_root_env_override(monkeypatch, tmp_path):
    monkeypatch.setenv("FVK_BENCH_WORKSPACE", str(tmp_path / "ws"))
    assert config.workspace_root() == tmp_path / "ws"
    monkeypatch.delenv("FVK_BENCH_WORKSPACE")
    assert config.workspace_root() == Path.home() / ".swe-fvk-runs"

def test_session_env_allowlist():
    env = config.session_env()
    assert set(env) == {"HOME", "PATH", "USER", "TERM", "LANG", "TZ"}
    assert env["TERM"] == "dumb" and env["LANG"] == "C.UTF-8" and env["TZ"] == "UTC"
    assert env["HOME"] == os.environ["HOME"]

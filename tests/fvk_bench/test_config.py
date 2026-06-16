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
    assert config.dataset_identity("verified500") == "princeton-nlp/SWE-bench_Verified"

def test_tested_claude_version_pinned():
    # The version this infra was validated against; doctor warns on mismatch.
    assert config.TESTED_CLAUDE_VERSION == "2.1.169"

def test_fvk_materials_copy_set():
    assert config.FVK_MATERIALS_FILES == (
        "README.md", "AGENTS.md", "commands/formalize.md", "commands/verify.md",
        "knowledge/intent-evidence.md", "knowledge/k-framework.md",
        "knowledge/matching-logic.md",
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


def test_registry_backward_compat_fvk45_and_verified500():
    from fvk_bench import config
    fvk = config.REGISTRY["fvk45"]
    assert fvk.dataset_identity == "princeton-nlp/SWE-bench_Verified"
    assert fvk.dataset_local is None
    assert fvk.expected_count == 45
    assert fvk.data_file == config.INSTANCES_JSON
    assert fvk.batch_scheme == "fvk45_fixed5"

    ver = config.REGISTRY["verified500"]
    assert ver.dataset_identity == "princeton-nlp/SWE-bench_Verified"
    assert ver.dataset_local is None
    assert ver.expected_count == 500
    assert ver.data_file == config.VERIFIED_INSTANCES_JSON
    assert ver.batch_scheme == "verified_sorted10"


def test_registry_multilingual300_entry():
    from fvk_bench import config
    ml = config.REGISTRY["multilingual300"]
    assert ml.dataset_identity == "SWE-bench/SWE-bench_Multilingual"
    assert ml.dataset_local == "third_party/swe-bench-multilingual"
    assert ml.expected_count == 300
    assert ml.data_file == config.MULTILINGUAL_INSTANCES_JSON
    assert ml.batch_scheme == "multilingual_sorted10"


def test_instance_sets_and_default():
    from fvk_bench import config
    assert config.INSTANCE_SETS == ("fvk45", "verified500", "multilingual300")
    assert config.DEFAULT_INSTANCE_SET == "fvk45"


def test_resolve_dataset_and_identity():
    from fvk_bench import config
    assert config.resolve_dataset("verified500") == "princeton-nlp/SWE-bench_Verified"
    assert config.dataset_identity("multilingual300") == "SWE-bench/SWE-bench_Multilingual"
    local = config.resolve_dataset("multilingual300")
    assert local.endswith("third_party/swe-bench-multilingual")
    assert local.startswith("/")  # absolute, resolved against REPO_ROOT

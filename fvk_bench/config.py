"""Single source of pinned benchmark parameters for the fvk 3-arm evaluation.

Every constant here is authoritative for the experiment. Changing any value
changes the experiment — reviewers should treat this module as the experiment
specification, not just implementation detail.
"""

import os
from dataclasses import dataclass
from pathlib import Path

# ---------------------------------------------------------------------------
# Pinned invocation constants
# ---------------------------------------------------------------------------

MODEL: str = "claude-opus-4-8"
EFFORT: str = "max"
MAX_TURNS: dict[str, int] = {"baseline": 200, "fvk": 200, "control": 200}
TOOLS: str = "Read,Write,Edit,Glob,Grep"  # passed verbatim to `claude --tools`; restricts actual built-in tool surface (NOT a permission list)
ARMS: tuple[str, ...] = ("baseline", "fvk", "control")
ARM_TIMEOUT_SECONDS: int = 4 * 3600
assert set(MAX_TURNS) == set(ARMS), "MAX_TURNS keys must match ARMS"

# ---------------------------------------------------------------------------
# FVK materials files to copy into the fvk arm workspace
# ---------------------------------------------------------------------------

FVK_MATERIALS_FILES: tuple[str, ...] = (
    "README.md",
    "AGENTS.md",
    "commands/formalize.md",
    "commands/verify.md",
    "knowledge/intent-evidence.md",
    "knowledge/k-framework.md",
    "knowledge/matching-logic.md",
    "knowledge/reachability-and-circularities.md",
    "knowledge/sources.md",
)

# ---------------------------------------------------------------------------
# Filesystem paths
# ---------------------------------------------------------------------------

REPO_ROOT: Path = Path(__file__).resolve().parent.parent
PACKAGE_DIR: Path = Path(__file__).resolve().parent
PROMPTS_DIR: Path = PACKAGE_DIR / "prompts"
INSTANCES_JSON: Path = PACKAGE_DIR / "data" / "instances.json"
VERIFIED_INSTANCES_JSON: Path = PACKAGE_DIR / "data" / "instances_verified500.json"
REPRO_SUBMODULE: Path = REPO_ROOT / "third_party" / "swebench-fvk-reproducibility"
FVK_SUBMODULE: Path = REPO_ROOT / "third_party" / "formal-verification-kit"
RESULTS_DIR: Path = REPO_ROOT / "results"
MULTILINGUAL_INSTANCES_JSON: Path = PACKAGE_DIR / "data" / "instances_multilingual300.json"
MULTILINGUAL_SUBMODULE: Path = REPO_ROOT / "third_party" / "swe-bench-multilingual"

# ---------------------------------------------------------------------------
# Instance-set registry (single source of truth for each runnable set)
# ---------------------------------------------------------------------------


@dataclass(frozen=True)
class InstanceSet:
    """One runnable instance set. Authoritative description of a benchmark set."""

    name: str
    dataset_identity: str       # portable logical name recorded in run manifests
    dataset_local: str | None   # repo-relative dir holding test.parquet, or None (HF)
    expected_count: int
    data_file: Path             # vendored *visible* metadata JSON (agent inputs)
    id_source: str              # "submodule45" | "count"
    batch_scheme: str           # "fvk45_fixed5" | "verified_sorted10" | "multilingual_sorted10"


REGISTRY: dict[str, "InstanceSet"] = {
    "fvk45": InstanceSet(
        name="fvk45",
        dataset_identity="princeton-nlp/SWE-bench_Verified",
        dataset_local=None,
        expected_count=45,
        data_file=INSTANCES_JSON,
        id_source="submodule45",
        batch_scheme="fvk45_fixed5",
    ),
    "verified500": InstanceSet(
        name="verified500",
        dataset_identity="princeton-nlp/SWE-bench_Verified",
        dataset_local=None,
        expected_count=500,
        data_file=VERIFIED_INSTANCES_JSON,
        id_source="count",
        batch_scheme="verified_sorted10",
    ),
    "multilingual300": InstanceSet(
        name="multilingual300",
        dataset_identity="SWE-bench/SWE-bench_Multilingual",
        dataset_local="third_party/swe-bench-multilingual",
        expected_count=300,
        data_file=MULTILINGUAL_INSTANCES_JSON,
        id_source="count",
        batch_scheme="multilingual_sorted10",
    ),
}

INSTANCE_SETS: tuple[str, ...] = tuple(REGISTRY)
DEFAULT_INSTANCE_SET: str = "fvk45"

# TEMPORARY backward-compat alias — removed in Task 6 once all consumers migrate.
DATASET_NAME: str = REGISTRY[DEFAULT_INSTANCE_SET].dataset_identity


def resolve_dataset(instance_set: str) -> str:
    """Return the dataset arg for the harness/loader for ``instance_set``.

    Sets with a local mirror return the absolute submodule dir (the harness loads
    ``<dir>/test.parquet``); others return the HuggingFace dataset name.
    """
    s = REGISTRY[instance_set]
    if s.dataset_local:
        return str((REPO_ROOT / s.dataset_local).resolve())
    return s.dataset_identity


def dataset_identity(instance_set: str) -> str:
    """Return the portable logical dataset name recorded in run manifests."""
    return REGISTRY[instance_set].dataset_identity


# ---------------------------------------------------------------------------
# Session / runner constants
# ---------------------------------------------------------------------------

PERMISSION_MODE: str = "bypassPermissions"  # value for `claude --permission-mode`; safe because the tool surface has no execution/network tools
SETTING_SOURCES: str = "project,local"  # value for `claude --setting-sources`; excludes user-level settings where personal skills/plugins/hooks live
CANARY_MODEL: str = "claude-haiku-4-5-20251001"  # cheap model used only by `doctor --canary` session-cleanliness probes, never for benchmark arms
TESTED_CLAUDE_VERSION: str = "2.1.169"  # the claude-code version this infra was validated against; doctor warns on mismatch

# ---------------------------------------------------------------------------
# Agent selection (which CLI drives the arms). Claude is the original/default;
# Codex is the second benchmark agent, run side-by-side via `--agent codex`.
# ---------------------------------------------------------------------------

AGENTS: tuple[str, ...] = ("claude", "codex")
DEFAULT_AGENT: str = "claude"

# Codex-side pinned invocation constants (mirror the Claude pins above; every
# value is part of the experiment specification for the codex arm).
CODEX_MODEL: str = "gpt-5.5"  # value for `codex exec -m`; reachable only under ChatGPT/Codex subscription auth (API-key auth caps at gpt-5.4)
CODEX_EFFORT: str = "xhigh"  # `-c model_reasoning_effort=`; Codex's top reasoning tier (the analogue of Claude's `--effort max`)
CODEX_SANDBOX: str = "workspace-write"  # value for `codex exec --sandbox`; must be able to write the fix (read-only cannot), execution is forbidden by prompt, not sandbox
TESTED_CODEX_VERSION: str = "0.132.0"  # codex-cli version this infra was written against; doctor warns on mismatch


# ---------------------------------------------------------------------------
# Functions
# ---------------------------------------------------------------------------


def workspace_root() -> Path:
    """Return the directory where benchmark run workspaces are created.

    Override with the ``FVK_BENCH_WORKSPACE`` environment variable; otherwise
    defaults to ``~/.swe-fvk-runs``.
    """
    raw = os.environ.get("FVK_BENCH_WORKSPACE")
    if raw:
        return Path(raw)
    return Path.home() / ".swe-fvk-runs"


def session_env() -> dict[str, str]:
    """Return a minimal, reproducible environment dict for benchmark sessions.

    Passes through the real ``HOME`` and ``PATH`` so tools can be located, but
    forces ``TERM``, ``LANG``, and ``TZ`` to deterministic values that avoid
    locale- or timezone-sensitive output differences between runs.
    """
    return {
        "HOME": os.environ["HOME"],
        "PATH": os.environ["PATH"],
        "USER": os.environ.get("USER", "bench"),
        "TERM": "dumb",
        "LANG": "C.UTF-8",
        "TZ": "UTC",
    }

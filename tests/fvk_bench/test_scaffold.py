"""Tests for fvk_bench.scaffold — written before implementation (TDD).

All git traffic stays on the local filesystem: ``ensure_mirror`` is steered at
the fixture repo by monkeypatching the ``fvk_bench.scaffold._clone_url`` hook,
and workspace tests clone from a ``file://`` mirror built directly with git.
"""

import dataclasses
import json
import subprocess
from pathlib import Path

import pytest

import fvk_bench.scaffold as scaffold

MISSING_SHA = "0" * 40


def _git_out(args: list[str], cwd: Path) -> str:
    """Run git in ``cwd`` and return stripped stdout (test-side helper)."""
    proc = subprocess.run(
        ["git", *args], cwd=cwd, check=True, capture_output=True, text=True
    )
    return proc.stdout.strip()


@pytest.fixture()
def mirror(fixture_remote_repo, tmp_path) -> Path:
    """Bare mirror of the fixture remote, as ensure_mirror would produce it."""
    remote_path, _ = fixture_remote_repo
    cache = tmp_path / "cache"
    cache.mkdir()
    dst = cache / "demo__demo.git"
    subprocess.run(
        ["git", "clone", "--mirror", f"file://{remote_path}", str(dst)],
        check=True,
        capture_output=True,
        text=True,
    )
    return dst


# ---------------------------------------------------------------------------
# 1. ensure_mirror clones once, then is a pure cache hit
# ---------------------------------------------------------------------------

def test_ensure_mirror_creates_once(fixture_remote_repo, tmp_path, monkeypatch):
    remote_path, _ = fixture_remote_repo
    cache = tmp_path / "cache"

    # _clone_url is the documented test hook: point it at the local fixture.
    monkeypatch.setattr(scaffold, "_clone_url", lambda repo: f"file://{remote_path}")

    mirror = scaffold.ensure_mirror("demo/demo", cache)

    assert mirror == cache / "demo__demo.git"
    assert mirror.is_dir()
    assert _git_out(["rev-parse", "--is-bare-repository"], cwd=mirror) == "true"

    mtime_before = mirror.stat().st_mtime_ns

    # Cache hit must not even compute a clone URL — a raising hook proves
    # ensure_mirror has no network path when the mirror already exists.
    def _boom(repo: str) -> str:
        raise AssertionError("network path taken on cache hit")

    monkeypatch.setattr(scaffold, "_clone_url", _boom)

    again = scaffold.ensure_mirror("demo/demo", cache)

    assert again == mirror
    assert mirror.stat().st_mtime_ns == mtime_before, "mirror was re-cloned"


# ---------------------------------------------------------------------------
# 1b. ensure_mirror leaves no mirror dir or *.tmp-* leftovers on clone failure
# ---------------------------------------------------------------------------

def test_ensure_mirror_clone_failure_raises(tmp_path, monkeypatch):
    """A failing clone must raise RuntimeError mentioning "clone" with no leftovers."""
    cache = tmp_path / "cache"
    monkeypatch.setattr(
        scaffold, "_clone_url", lambda repo: "file:///nonexistent/nowhere.git"
    )

    with pytest.raises(RuntimeError, match="clone"):
        scaffold.ensure_mirror("demo/demo", cache)

    # No mirror directory must exist.
    mirror_path = cache / "demo__demo.git"
    assert not mirror_path.exists(), "partial mirror dir must not survive a failed clone"

    # No *.tmp-* leftovers must remain.
    tmp_leftovers = list(cache.glob("*.tmp-*"))
    assert tmp_leftovers == [], f"stale tmp dirs must be cleaned up: {tmp_leftovers}"


# ---------------------------------------------------------------------------
# 2. create_workspace produces exactly the specified tree
# ---------------------------------------------------------------------------

def test_create_workspace_tree_exact(fixture_instance, mirror, tmp_path):
    ws_root = tmp_path / "ws_root"

    ws = scaffold.create_workspace("run-1", fixture_instance, ws_root, mirror)

    assert ws == ws_root / "run-1" / fixture_instance.instance_id

    # Exact top level: nothing more, nothing less.
    assert {p.name for p in ws.iterdir()} == {"benchmark", "repo", "reports", ".fvk_bench"}

    # Arms created later must NOT be pre-created.
    for forbidden in ("fvk", "review", "fvk_materials"):
        assert not (ws / forbidden).exists(), f"{forbidden}/ must not exist"

    assert {p.name for p in (ws / "benchmark").iterdir()} == {"PROBLEM.md", "instance.json"}

    assert (ws / "reports").is_dir()
    assert list((ws / "reports").iterdir()) == []

    private = ws / ".fvk_bench"
    assert {p.name for p in private.iterdir()} == {
        "prompts", "raw", "artifacts", "solutions", "scaffolded",
    }
    for sub in ("prompts", "raw", "artifacts", "solutions"):
        assert (private / sub).is_dir()
        assert list((private / sub).iterdir()) == []
    assert (private / "scaffolded").is_file()
    assert (private / "scaffolded").read_text().strip(), "marker should hold a timestamp"

    assert (ws / "repo" / ".git").exists()
    assert (ws / "repo" / "lib.py").is_file()

    # PROBLEM.md is exactly the rendered problem statement.
    assert (ws / "benchmark" / "PROBLEM.md").read_text(
        encoding="utf-8"
    ) == scaffold.render_problem_md(fixture_instance)

    # instance.json: exactly the 4 public keys, indent=2, trailing newline.
    raw = (ws / "benchmark" / "instance.json").read_text(encoding="utf-8")
    data = json.loads(raw)
    assert set(data) == {"instance_id", "repo", "base_commit", "version"}
    assert data == {
        "instance_id": "demo__demo-1",
        "repo": "demo/demo",
        "base_commit": fixture_instance.base_commit,
        "version": "1.0",
    }
    assert raw == json.dumps(data, indent=2) + "\n"


# ---------------------------------------------------------------------------
# 3. repo/ is a clean detached checkout at base_commit with no remote/hooks
# ---------------------------------------------------------------------------

def test_repo_checkout_detached_at_base(fixture_instance, mirror, tmp_path):
    ws = scaffold.create_workspace("run-1", fixture_instance, tmp_path / "ws_root", mirror)
    repo = ws / "repo"

    assert _git_out(["rev-parse", "HEAD"], cwd=repo) == fixture_instance.base_commit
    assert _git_out(["rev-parse", "--abbrev-ref", "HEAD"], cwd=repo) == "HEAD"  # detached
    assert _git_out(["status", "--porcelain"], cwd=repo) == ""
    assert _git_out(["config", "core.hooksPath"], cwd=repo) == "/dev/null"
    assert _git_out(["remote"], cwd=repo) == "", "sessions must not see a usable remote"

    # Working tree is the commit-1 version: subtract() does not exist yet.
    lib = (repo / "lib.py").read_text(encoding="utf-8")
    assert lib == "def add(a, b):\n    return a + b\n"
    assert "subtract" not in lib


# ---------------------------------------------------------------------------
# 4. render_problem_md includes hints only when non-blank
# ---------------------------------------------------------------------------

def test_problem_md_hints_only_when_present(fixture_instance):
    no_hints = scaffold.render_problem_md(fixture_instance)
    assert no_hints == (
        "# demo__demo-1: issue from demo/demo\n\nadd() mishandles negative zero.\n"
    )
    assert "## Hints" not in no_hints

    blank_hints = dataclasses.replace(fixture_instance, hints_text="   \n")
    assert "## Hints" not in scaffold.render_problem_md(blank_hints)

    with_hints = dataclasses.replace(fixture_instance, hints_text="try X")
    rendered = scaffold.render_problem_md(with_hints)
    assert rendered == (
        "# demo__demo-1: issue from demo/demo\n\nadd() mishandles negative zero.\n"
        "\n## Hints (public)\n\ntry X\n"
    )


# ---------------------------------------------------------------------------
# 5. create_workspace is idempotent once the scaffolded marker exists
# ---------------------------------------------------------------------------

def test_create_workspace_idempotent(fixture_instance, mirror, tmp_path):
    ws_root = tmp_path / "ws_root"
    ws = scaffold.create_workspace("run-1", fixture_instance, ws_root, mirror)

    # Simulate a session having edited the checkout.
    lib = ws / "repo" / "lib.py"
    lib.write_text("def add(a, b):\n    return a + b  # session edit\n", encoding="utf-8")
    marker_mtime = (ws / ".fvk_bench" / "scaffolded").stat().st_mtime_ns

    again = scaffold.create_workspace("run-1", fixture_instance, ws_root, mirror)

    assert again == ws
    assert lib.read_text(encoding="utf-8").endswith("# session edit\n"), (
        "second create_workspace must not touch repo/"
    )
    assert (ws / ".fvk_bench" / "scaffolded").stat().st_mtime_ns == marker_mtime


# ---------------------------------------------------------------------------
# 6. missing base commit: one refresh attempt, then RuntimeError
# ---------------------------------------------------------------------------

def test_checkout_missing_commit_raises(fixture_instance, mirror, tmp_path, monkeypatch):
    bad = dataclasses.replace(fixture_instance, base_commit=MISSING_SHA)

    refresh_calls: list[tuple[str, Path]] = []
    real_refresh = scaffold.refresh_mirror

    def counting_refresh(repo: str, cache_dir: Path) -> None:
        refresh_calls.append((repo, cache_dir))
        real_refresh(repo, cache_dir)  # harmless against the file:// mirror

    monkeypatch.setattr(scaffold, "refresh_mirror", counting_refresh)

    with pytest.raises(RuntimeError) as exc_info:
        scaffold.create_workspace("run-1", bad, tmp_path / "ws_root", mirror)

    assert MISSING_SHA in str(exc_info.value)
    assert refresh_calls == [("demo/demo", mirror.parent)], (
        "exactly one refresh attempt before giving up"
    )

    # Marker must not exist after a failed scaffold (it is written last).
    assert not (tmp_path / "ws_root" / "run-1" / "demo__demo-1" / ".fvk_bench" / "scaffolded").exists()

"""Shared fixtures for fvk_bench tests.

Provides a tiny local git repository that stands in for a GitHub remote
(``fixture_remote_repo``) and a matching :class:`Instance` pinned at the
repo's first commit (``fixture_instance``). Later task suites (sessions,
runner) reuse these to exercise workspace-shaped code without network access.
"""

import subprocess
from pathlib import Path

import pytest

from fvk_bench.instances import Instance


def _run_git(args: list[str], cwd: Path) -> str:
    """Run git in ``cwd`` for fixture setup; return stdout."""
    proc = subprocess.run(
        ["git", *args], cwd=cwd, check=True, capture_output=True, text=True
    )
    return proc.stdout


@pytest.fixture(scope="session")
def fixture_remote_repo(tmp_path_factory) -> tuple[Path, str]:
    """Build a tiny two-commit git repo standing in for a GitHub remote.

    Commit 1: ``lib.py`` with only ``add()`` plus a trivial test file.
    Commit 2: ``lib.py`` gains ``subtract()`` — so a checkout at commit 1 is
    distinguishable from the branch tip.

    Returns ``(repo_path, first_commit_sha)``.
    """
    repo = tmp_path_factory.mktemp("remote_repo")
    _run_git(["init", "-q"], cwd=repo)
    _run_git(["config", "user.email", "fixture@local"], cwd=repo)
    _run_git(["config", "user.name", "fixture"], cwd=repo)
    _run_git(["config", "commit.gpgsign", "false"], cwd=repo)

    (repo / "lib.py").write_text("def add(a, b):\n    return a + b\n", encoding="utf-8")
    tests_dir = repo / "tests"
    tests_dir.mkdir()
    (tests_dir / "test_lib.py").write_text(
        "from lib import add\n\n\ndef test_add():\n    assert add(1, 2) == 3\n",
        encoding="utf-8",
    )
    _run_git(["add", "-A"], cwd=repo)
    _run_git(["commit", "-q", "-m", "commit 1: add()"], cwd=repo)
    first_commit_sha = _run_git(["rev-parse", "HEAD"], cwd=repo).strip()

    (repo / "lib.py").write_text(
        "def add(a, b):\n    return a + b\n\n\ndef subtract(a, b):\n    return a - b\n",
        encoding="utf-8",
    )
    _run_git(["add", "-A"], cwd=repo)
    _run_git(["commit", "-q", "-m", "commit 2: subtract()"], cwd=repo)

    return repo, first_commit_sha


@pytest.fixture()
def fixture_instance(fixture_remote_repo) -> Instance:
    """An Instance for repo "demo/demo" pinned at the fixture repo's commit 1."""
    _, first_commit_sha = fixture_remote_repo
    return Instance(
        instance_id="demo__demo-1",
        repo="demo/demo",
        base_commit=first_commit_sha,
        version="1.0",
        problem_statement="add() mishandles negative zero.",
        hints_text="",
        fail_to_pass_count=1,
        pass_to_pass_count=1,
    )

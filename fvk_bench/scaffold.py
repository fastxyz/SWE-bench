"""Per-instance workspace scaffolding for fvk benchmark runs.

Workspaces live outside this repository (see :func:`fvk_bench.config.workspace_root`)
so sessions get a hermetic cwd. Target GitHub repos are cloned once into a bare
mirror cache; each instance workspace then gets a local clone checked out
(detached) at the instance's base commit, plus the benchmark input files.

Only the directories every arm needs are created here — ``fvk/``, ``review/``
and ``fvk_materials/`` are created later by the arms that use them.
"""

import json
import os
import shutil
import subprocess
import uuid
from datetime import datetime, timezone
from pathlib import Path

from fvk_bench.instances import Instance

#: Directories created inside every workspace (relative to the workspace root).
_WORKSPACE_DIRS: tuple[str, ...] = (
    "benchmark",
    "reports",
    ".fvk_bench/prompts",
    ".fvk_bench/raw",
    ".fvk_bench/artifacts",
    ".fvk_bench/solutions",
)

#: Marker file written last; its presence means the workspace is fully scaffolded.
_SCAFFOLDED_MARKER = ".fvk_bench/scaffolded"


def _git(
    *args: str, cwd: Path | None = None, git_dir: Path | None = None
) -> subprocess.CompletedProcess:
    """Run one git command, raising RuntimeError with command + stderr on failure.

    Every git invocation in this module goes through here: output is always
    captured (no prints), ``shell=True`` is never used.
    """
    cmd = ["git"]
    if git_dir is not None:
        cmd += ["--git-dir", str(git_dir)]
    cmd += list(args)
    try:
        return subprocess.run(cmd, cwd=cwd, check=True, capture_output=True, text=True)
    except subprocess.CalledProcessError as exc:
        raise RuntimeError(
            f"git command failed: {' '.join(cmd)}\n{(exc.stderr or '').strip()}"
        ) from exc


def _clone_url(repo: str) -> str:
    """Return the clone URL for ``repo`` ("org/name").

    Test hook: the test suite monkeypatches this function to return a local
    ``file://`` URL so :func:`ensure_mirror` is exercised without network access.
    """
    return f"https://github.com/{repo}.git"


def _mirror_path(repo: str, cache_dir: Path) -> Path:
    """Map "org/name" to ``cache_dir/org__name.git``."""
    org, name = repo.split("/", 1)
    return Path(cache_dir) / f"{org}__{name}.git"


def _clone_tmp_path(dst: Path) -> Path:
    """Temp sibling of ``dst`` for the atomic mirror clone.

    The suffix combines pid and a uuid4 fragment: pid alone is not unique
    across threads of one process, and ``run --max-parallel`` clones from
    worker threads.
    """
    return dst.with_name(f"{dst.name}.tmp-{os.getpid()}-{uuid.uuid4().hex[:8]}")


def ensure_mirror(repo: str, cache_dir: Path) -> Path:
    """Return the bare mirror of ``repo`` under ``cache_dir``, cloning on first use.

    A cache hit returns immediately with no subprocess or network activity, so
    22 instances of one repo cost one GitHub clone, not 22.

    Clone-safety: the actual clone goes into a thread-unique
    ``<dst>.tmp-<pid>-<uuid>`` sibling so a kill-9 mid-clone never leaves a
    half-initialised directory that would be mistaken for a valid cache entry.
    On success the temp dir is atomically renamed to ``dst``; if ``dst``
    already exists (lost race or pre-existing) the temp dir is discarded and
    the winner is returned.  Any stale ``*.tmp-*`` siblings left by a previous
    process are removed (best effort) before the clone starts.
    """
    dst = _mirror_path(repo, cache_dir)
    if dst.exists():
        return dst
    Path(cache_dir).mkdir(parents=True, exist_ok=True)

    # Best-effort: clean up stale temp dirs from previous killed processes.
    for stale in Path(cache_dir).glob(f"{dst.name}.tmp-*"):
        try:
            shutil.rmtree(stale)
        except Exception:  # noqa: BLE001
            pass

    tmp = _clone_tmp_path(dst)
    try:
        _git("clone", "--mirror", _clone_url(repo), str(tmp))
    except Exception:
        # Clean up partial clone so it can never be a cache hit.
        try:
            shutil.rmtree(tmp)
        except Exception:  # noqa: BLE001
            pass
        raise
    try:
        os.rename(tmp, dst)
    except OSError:
        # dst appeared between our check and rename (lost race or pre-existing).
        try:
            shutil.rmtree(tmp)
        except Exception:  # noqa: BLE001
            pass
    return dst


def refresh_mirror(repo: str, cache_dir: Path) -> None:
    """Fetch all refs into the existing mirror of ``repo``.

    Used only when a base commit is missing from the cached mirror (e.g. the
    mirror predates the commit).
    """
    mirror = _mirror_path(repo, cache_dir)
    _git("fetch", "--all", "--prune", "--quiet", git_dir=mirror)


def render_problem_md(inst: Instance) -> str:
    """Render benchmark/PROBLEM.md: problem statement plus optional public hints."""
    text = f"# {inst.instance_id}: issue from {inst.repo}\n\n{inst.problem_statement}\n"
    if inst.hints_text.strip():
        text += f"\n## Hints (public)\n\n{inst.hints_text}\n"
    return text


def _clone_repo(mirror: Path, repo_dir: Path) -> None:
    """Clone the mirror into ``repo_dir``, replacing any partial previous clone."""
    if repo_dir.exists():
        shutil.rmtree(repo_dir)
    _git("clone", "--no-hardlinks", f"file://{mirror.resolve()}", str(repo_dir))


def create_workspace(run_id: str, inst: Instance, ws_root: Path, mirror: Path) -> Path:
    """Create (or return) the workspace for ``inst`` under ``ws_root/run_id``.

    ``mirror`` MUST be the bare mirror directory returned by :func:`ensure_mirror`
    (not the cache directory that contains it).

    Idempotent: once the scaffolded marker exists the workspace is returned
    untouched — sessions may already have edited ``repo/``.

    Raises:
        RuntimeError: if ``inst.base_commit`` cannot be checked out even after
            refreshing the mirror once, or if any git command fails.
    """
    ws = Path(ws_root) / run_id / inst.instance_id
    marker = ws / _SCAFFOLDED_MARKER
    if marker.exists():
        return ws

    # Create .fvk_bench explicitly before its children so it always exists as a
    # plain directory (not implicitly via a deeper mkdir parents=True call).
    (ws / ".fvk_bench").mkdir(parents=True, exist_ok=True)
    for rel in _WORKSPACE_DIRS:
        (ws / rel).mkdir(parents=True, exist_ok=True)

    (ws / "benchmark" / "PROBLEM.md").write_text(
        render_problem_md(inst), encoding="utf-8"
    )
    # Public metadata only — never test names, counts, or patches.
    public_meta = {
        "instance_id": inst.instance_id,
        "repo": inst.repo,
        "base_commit": inst.base_commit,
        "version": inst.version,
    }
    (ws / "benchmark" / "instance.json").write_text(
        json.dumps(public_meta, indent=2) + "\n", encoding="utf-8"
    )

    repo_dir = ws / "repo"
    _clone_repo(mirror, repo_dir)
    try:
        _git("checkout", "-q", "--detach", inst.base_commit, cwd=repo_dir)
    except RuntimeError:
        # Stale mirror? Refresh once, re-clone, retry; a second failure means
        # the commit genuinely doesn't exist upstream — propagate it.
        refresh_mirror(inst.repo, mirror.parent)
        _clone_repo(mirror, repo_dir)
        _git("checkout", "-q", "--detach", inst.base_commit, cwd=repo_dir)

    _git("config", "core.hooksPath", "/dev/null", cwd=repo_dir)
    _git("config", "user.email", "bench@local", cwd=repo_dir)
    _git("config", "user.name", "fvk-bench", cwd=repo_dir)
    # Drop the network remote: sessions must not see a usable remote.
    _git("remote", "remove", "origin", cwd=repo_dir)

    # Written last so a crash anywhere above leaves no marker and the next
    # call rebuilds the workspace from scratch.
    marker.write_text(datetime.now(timezone.utc).isoformat() + "\n", encoding="utf-8")
    return ws

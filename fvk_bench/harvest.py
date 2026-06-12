"""Harvest durable benchmark artifacts into the results/ tree.

Two public functions:

- :func:`harvest_instance`: copies artifacts from a completed workspace into
  ``results/<run_id>/<instance_id>/``, augmenting ``state.json`` with
  ``template_hashes`` and parsed raw envelopes into ``manifest.json``.

- :func:`write_run_manifest`: writes a run-level ``run_manifest.json`` under
  ``results/<run_id>/`` capturing host metadata, invocation parameters, git
  state and the benchmark version.

Both functions are idempotent: re-running them overwrites existing output.
Neither function crashes on absent optional artifacts; they simply skip them
and, where relevant, record which pieces were missing.
"""

import gzip
import json
import os
import platform
import shutil
import socket
import subprocess
from datetime import datetime, timezone
from pathlib import Path

import fvk_bench
from fvk_bench import config
from fvk_bench import claude_runner, prompting
from fvk_bench.instances import Instance


def _utc_now_iso() -> str:
    return datetime.now(timezone.utc).isoformat()


def _copy_if_exists(src: Path, dst: Path) -> bool:
    """Copy ``src`` to ``dst``, creating parent dirs. Returns True if copied."""
    if not src.exists():
        return False
    dst.parent.mkdir(parents=True, exist_ok=True)
    if src.is_dir():
        shutil.copytree(src, dst, dirs_exist_ok=True)
    else:
        shutil.copy2(src, dst)
    return True


def _copytree_contents(src_dir: Path, dst_dir: Path) -> bool:
    """Copy all contents of ``src_dir`` into ``dst_dir``. Returns True if copied."""
    if not src_dir.is_dir():
        return False
    dst_dir.mkdir(parents=True, exist_ok=True)
    shutil.copytree(src_dir, dst_dir, dirs_exist_ok=True)
    return True


def harvest_instance(
    ws: Path,
    run_id: str,
    inst: Instance,
    results_dir: Path = config.RESULTS_DIR,
) -> Path:
    """Harvest one instance's artifacts from workspace ``ws`` into ``results_dir``.

    Destination: ``results_dir/run_id/inst.instance_id``.

    Files copied (only what exists; missing files are never fatal):
    - ``state.json`` content → ``dst/manifest.json`` augmented with
      ``template_hashes`` and ``raw_envelopes``
    - ``.fvk_bench/prompts/<arm>.md`` → ``dst/prompts/<arm>.md``
    - ``.fvk_bench/solutions/solution_<arm>.patch`` → ``dst/solutions/``
    - ``.fvk_bench/artifacts/baseline/reports/baseline_notes.md``
      → ``dst/reports/baseline_notes.md`` (same for fvk/control)
    - ``.fvk_bench/artifacts/fvk/fvk/*`` → ``dst/fvk/*``
    - ``.fvk_bench/artifacts/control/review/*`` → ``dst/review/*``
    - For each arm with a ``session_id``: transcript gzip-compressed to
      ``dst/transcripts/<arm>.jsonl.gz``; missing transcripts recorded in
      manifest as ``transcript_missing: [<arm>, ...]``

    Returns ``dst``.
    """
    ws = Path(ws)
    results_dir = Path(results_dir)
    dst = results_dir / run_id / inst.instance_id
    dst.mkdir(parents=True, exist_ok=True)

    fvk_bench_dir = ws / ".fvk_bench"

    # --- Load state.json ---------------------------------------------------
    state_path = fvk_bench_dir / "state.json"
    if state_path.exists():
        state = json.loads(state_path.read_text(encoding="utf-8"))
    else:
        state = {}

    # --- raw_envelopes: parse each arm's .stdout.json ----------------------
    raw_envelopes: dict = {}
    for arm in config.ARMS:
        raw_path = fvk_bench_dir / "raw" / f"{arm}.stdout.json"
        if raw_path.exists():
            try:
                parsed = json.loads(raw_path.read_text(encoding="utf-8"))
                raw_envelopes[arm] = parsed if isinstance(parsed, dict) else None
            except (ValueError, OSError):
                raw_envelopes[arm] = None
        else:
            raw_envelopes[arm] = None

    # --- template_hashes ---------------------------------------------------
    th = prompting.template_hashes()

    # --- transcript harvesting ---------------------------------------------
    transcript_missing: list[str] = []
    transcripts_dir = dst / "transcripts"
    arms_state = state.get("arms", {})
    for arm in config.ARMS:
        arm_state = arms_state.get(arm, {})
        sid = arm_state.get("session_id")
        if not sid:
            continue  # no session_id → nothing to harvest
        transcript = claude_runner.transcript_path(ws, sid)
        if transcript is None or not transcript.exists():
            transcript_missing.append(arm)
            continue
        transcripts_dir.mkdir(parents=True, exist_ok=True)
        gz_path = transcripts_dir / f"{arm}.jsonl.gz"
        raw_bytes = transcript.read_bytes()
        with gzip.open(gz_path, "wb") as f:
            f.write(raw_bytes)

    # --- Build manifest = state + augmentations ----------------------------
    manifest = dict(state)
    manifest["template_hashes"] = th
    manifest["raw_envelopes"] = raw_envelopes
    if transcript_missing:
        manifest["transcript_missing"] = transcript_missing

    manifest_path = dst / "manifest.json"
    manifest_path.write_text(json.dumps(manifest, indent=2), encoding="utf-8")

    # --- prompts -----------------------------------------------------------
    for arm in config.ARMS:
        src = fvk_bench_dir / "prompts" / f"{arm}.md"
        _copy_if_exists(src, dst / "prompts" / f"{arm}.md")

    # --- solutions (patches, including empty ones) -------------------------
    for arm in config.ARMS:
        src = fvk_bench_dir / "solutions" / f"solution_{arm}.patch"
        _copy_if_exists(src, dst / "solutions" / f"solution_{arm}.patch")

    # --- reports: baseline/fvk/control notes -------------------------------
    for arm, note_name in [
        ("baseline", "baseline_notes.md"),
        ("fvk", "fvk_notes.md"),
        ("control", "control_notes.md"),
    ]:
        src = fvk_bench_dir / "artifacts" / arm / "reports" / note_name
        _copy_if_exists(src, dst / "reports" / note_name)

    # --- fvk arm artifacts: .fvk_bench/artifacts/fvk/fvk/ → dst/fvk/ -----
    fvk_art_dir = fvk_bench_dir / "artifacts" / "fvk" / "fvk"
    if fvk_art_dir.is_dir():
        _copytree_contents(fvk_art_dir, dst / "fvk")

    # --- control arm artifacts: .fvk_bench/artifacts/control/review/ → dst/review/ ---
    control_art_dir = fvk_bench_dir / "artifacts" / "control" / "review"
    if control_art_dir.is_dir():
        _copytree_contents(control_art_dir, dst / "review")

    return dst


def write_run_manifest(
    run_id: str,
    results_dir: Path = config.RESULTS_DIR,
    extra: dict | None = None,
) -> Path:
    """Write a run-level manifest at ``results_dir/run_id/run_manifest.json``.

    Captured fields:
    - ``run_id``, ``created_utc``
    - ``host``: hostname, os, arch, python version
    - ``claude_version``: from ``<claude-bin> --version`` (None on failure)
    - ``invocation``: model, effort, max_turns, tools, permission_mode,
      setting_sources
    - ``dataset``, ``template_hashes``, ``fvk_bench_version``
    - ``git``: repo_sha, submodules (path → sha dict)
    - any caller-supplied ``extra`` keys, merged into the manifest top level
      (e.g. ``max_parallel`` from the run command)

    Returns the path to the written file.
    """
    results_dir = Path(results_dir)
    run_dir = results_dir / run_id
    run_dir.mkdir(parents=True, exist_ok=True)
    out_path = run_dir / "run_manifest.json"

    # host info
    host = {
        "hostname": socket.gethostname(),
        "os": platform.platform(),
        "arch": platform.machine(),
        "python": platform.python_version(),
    }

    # claude version
    claude_bin = os.environ.get("FVK_BENCH_CLAUDE_BIN", "claude")
    claude_version: str | None = None
    try:
        proc = subprocess.run(
            [claude_bin, "--version"],
            capture_output=True,
            text=True,
            timeout=15,
        )
        if proc.returncode == 0:
            claude_version = proc.stdout.strip() or None
    except Exception:
        claude_version = None

    # git repo sha
    repo_sha: str | None = None
    try:
        proc = subprocess.run(
            ["git", "rev-parse", "HEAD"],
            cwd=str(config.REPO_ROOT),
            capture_output=True,
            text=True,
            timeout=15,
        )
        if proc.returncode == 0:
            repo_sha = proc.stdout.strip() or None
    except Exception:
        repo_sha = None

    # git submodules
    submodules: dict | None = None
    try:
        proc = subprocess.run(
            ["git", "submodule", "status"],
            cwd=str(config.REPO_ROOT),
            capture_output=True,
            text=True,
            timeout=15,
        )
        if proc.returncode == 0:
            submodules = {}
            for line in proc.stdout.splitlines():
                # Format: [ +-U]<sha> <path> [<describe>]
                line = line.strip()
                if not line:
                    continue
                # First char may be ' ', '+', '-', 'U' (status indicator)
                parts = line.split()
                if len(parts) >= 2:
                    sha = parts[0].lstrip("+-U")
                    path = parts[1]
                    submodules[path] = sha
    except Exception:
        submodules = None

    manifest = {
        "run_id": run_id,
        "created_utc": _utc_now_iso(),
        "host": host,
        "claude_version": claude_version,
        "invocation": {
            "model": config.MODEL,
            "effort": config.EFFORT,
            "max_turns": config.MAX_TURNS,
            "tools": config.TOOLS,
            "permission_mode": config.PERMISSION_MODE,
            "setting_sources": config.SETTING_SOURCES,
        },
        "dataset": config.DATASET_NAME,
        "template_hashes": prompting.template_hashes(),
        "fvk_bench_version": fvk_bench.__version__,
        "git": {
            "repo_sha": repo_sha,
            "submodules": submodules,
        },
    }
    manifest.update(extra or {})

    out_path.write_text(json.dumps(manifest, indent=2), encoding="utf-8")
    return out_path

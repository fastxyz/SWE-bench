"""Tests for fvk_bench.harvest — written TDD-style before implementation.

We never run Claude; we build a fake completed workspace by hand in tmp_path,
then assert the harvest output is exactly right. Transcript path monkeypatching
mirrors the pattern from test_claude_runner.py.
"""

import gzip
import json
import re
import subprocess
from pathlib import Path

import pytest

import fvk_bench.claude_runner as claude_runner
import fvk_bench.harvest as harvest
from fvk_bench import config
from fvk_bench.instances import Instance

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

SID_BASELINE = "aaaa0000-0000-0000-0000-000000000001"
SID_FVK = "aaaa0000-0000-0000-0000-000000000002"
SID_CONTROL = None  # control arm failed

INSTANCE_ID = "django__django-99999"
RUN_ID = "run-test-harvest-001"

FAKE_INSTANCE = Instance(
    instance_id=INSTANCE_ID,
    repo="django/django",
    base_commit="deadbeef" * 5 + "dead",  # 40-char hex
    version="4.2",
    problem_statement="Test problem.",
    hints_text="",
    fail_to_pass_count=2,
    pass_to_pass_count=5,
)

BASELINE_TRANSCRIPT_CONTENT = b'{"type":"assistant","message":{"content":[]}}\n'
FVK_TRANSCRIPT_CONTENT = b'{"type":"user","message":{"content":"ok"}}\n'

RAW_BASELINE_ENVELOPE = {"type": "result", "subtype": "success", "session_id": SID_BASELINE, "num_turns": 10}
RAW_FVK_ENVELOPE = {"type": "result", "subtype": "success", "session_id": SID_FVK, "num_turns": 15}


def _make_state(*, baseline_status="completed", fvk_status="completed", control_status="failed") -> dict:
    return {
        "run_id": RUN_ID,
        "instance_id": INSTANCE_ID,
        "baseline_session_id": SID_BASELINE,
        "core_hash_post_baseline": "abcdef1234567890",
        "arms": {
            "baseline": {
                "status": baseline_status,
                "reason": None,
                "session_id": SID_BASELINE,
                "attempts": 1,
                "started_at": "2024-01-01T00:00:00+00:00",
                "ended_at": "2024-01-01T01:00:00+00:00",
                "num_turns": 10,
                "duration_seconds": 3600.0,
                "audit": {"ok": True, "tool_uses": {}, "violations": [], "marker_warnings": [], "unparseable_lines": 0, "lines": 5},
            },
            "fvk": {
                "status": fvk_status,
                "reason": None,
                "session_id": SID_FVK,
                "attempts": 1,
                "started_at": "2024-01-01T01:00:00+00:00",
                "ended_at": "2024-01-01T02:00:00+00:00",
                "num_turns": 15,
                "duration_seconds": 3600.0,
                "audit": {"ok": True, "tool_uses": {}, "violations": [], "marker_warnings": [], "unparseable_lines": 0, "lines": 8},
            },
            "control": {
                "status": control_status,
                "reason": "agent_error" if control_status == "failed" else None,
                "session_id": SID_CONTROL,
                "attempts": 1,
                "started_at": "2024-01-01T02:00:00+00:00",
                "ended_at": "2024-01-01T02:05:00+00:00",
                "num_turns": None,
                "duration_seconds": 300.0,
                "audit": None,
            },
        },
    }


def _build_fake_workspace(ws: Path, tmp_home: Path, state: dict | None = None) -> None:
    """Build a realistic fake workspace tree for harvest tests."""
    fvk_bench_dir = ws / ".fvk_bench"

    # state.json
    if state is None:
        state = _make_state()
    (fvk_bench_dir).mkdir(parents=True, exist_ok=True)
    (fvk_bench_dir / "state.json").write_text(json.dumps(state, indent=2), encoding="utf-8")

    # prompts
    prompts_dir = fvk_bench_dir / "prompts"
    prompts_dir.mkdir(parents=True, exist_ok=True)
    (prompts_dir / "baseline.md").write_text("baseline prompt text", encoding="utf-8")
    (prompts_dir / "fvk.md").write_text("fvk prompt text", encoding="utf-8")
    # control prompt is intentionally absent (tolerated)

    # solutions (two patches: baseline non-empty, fvk empty)
    solutions_dir = fvk_bench_dir / "solutions"
    solutions_dir.mkdir(parents=True, exist_ok=True)
    (solutions_dir / "solution_baseline.patch").write_bytes(b"diff --git a/x.py b/x.py\n+fix\n")
    (solutions_dir / "solution_fvk.patch").write_bytes(b"")  # empty patch

    # artifacts: baseline
    baseline_art = fvk_bench_dir / "artifacts" / "baseline"
    (baseline_art / "reports").mkdir(parents=True, exist_ok=True)
    (baseline_art / "reports" / "baseline_notes.md").write_text("# Baseline Notes", encoding="utf-8")

    # artifacts: fvk with fvk/ subtree
    fvk_art = fvk_bench_dir / "artifacts" / "fvk"
    (fvk_art / "reports").mkdir(parents=True, exist_ok=True)
    (fvk_art / "reports" / "fvk_notes.md").write_text("# FVK Notes", encoding="utf-8")
    (fvk_art / "fvk").mkdir(parents=True, exist_ok=True)
    (fvk_art / "fvk" / "SPEC.md").write_text("# Spec", encoding="utf-8")
    (fvk_art / "fvk" / "proof.k").write_text("rule: foo", encoding="utf-8")

    # artifacts: control with review/ subtree (absent — control failed, so no artifacts)

    # raw envelopes
    raw_dir = fvk_bench_dir / "raw"
    raw_dir.mkdir(parents=True, exist_ok=True)
    (raw_dir / "baseline.stdout.json").write_text(json.dumps(RAW_BASELINE_ENVELOPE), encoding="utf-8")
    (raw_dir / "fvk.stdout.json").write_text(json.dumps(RAW_FVK_ENVELOPE), encoding="utf-8")
    # control raw is absent (failed before output)

    # fake transcripts under monkeypatched home
    # baseline transcript
    _plant_transcript(ws, tmp_home, SID_BASELINE, BASELINE_TRANSCRIPT_CONTENT)
    # fvk transcript
    _plant_transcript(ws, tmp_home, SID_FVK, FVK_TRANSCRIPT_CONTENT)


def _plant_transcript(ws: Path, tmp_home: Path, sid: str, content: bytes) -> Path:
    """Plant a fake transcript at the location transcript_path() expects."""
    munged = claude_runner._munge(str(ws.resolve()))
    tdir = tmp_home / ".claude" / "projects" / munged
    tdir.mkdir(parents=True, exist_ok=True)
    p = tdir / f"{sid}.jsonl"
    p.write_bytes(content)
    return p


# ---------------------------------------------------------------------------
# Test 1: exact layout
# ---------------------------------------------------------------------------

def test_harvest_layout_exact(tmp_path, monkeypatch):
    """harvest_instance produces the exact expected dst tree."""
    tmp_home = tmp_path / "home"
    monkeypatch.setattr(Path, "home", classmethod(lambda cls: tmp_home))

    ws = tmp_path / "ws"
    ws.mkdir()
    results_dir = tmp_path / "results"

    _build_fake_workspace(ws, tmp_home)

    dst = harvest.harvest_instance(ws, RUN_ID, FAKE_INSTANCE, results_dir)

    assert dst == results_dir / RUN_ID / INSTANCE_ID

    # manifest.json
    manifest_path = dst / "manifest.json"
    assert manifest_path.exists()
    manifest = json.loads(manifest_path.read_text(encoding="utf-8"))

    # state keys present
    assert manifest["run_id"] == RUN_ID
    assert manifest["instance_id"] == INSTANCE_ID
    assert "arms" in manifest
    assert "core_hash_post_baseline" in manifest

    # template_hashes present and correct shape
    assert "template_hashes" in manifest
    th = manifest["template_hashes"]
    assert set(th.keys()) == {"baseline", "fvk", "control"}
    for v in th.values():
        assert re.match(r"^[0-9a-f]{64}$", v)

    # raw_envelopes: baseline and fvk parsed, control None (no file)
    assert "raw_envelopes" in manifest
    re_map = manifest["raw_envelopes"]
    assert re_map["baseline"] == RAW_BASELINE_ENVELOPE
    assert re_map["fvk"] == RAW_FVK_ENVELOPE
    assert re_map["control"] is None

    # prompts/
    assert (dst / "prompts" / "baseline.md").read_text(encoding="utf-8") == "baseline prompt text"
    assert (dst / "prompts" / "fvk.md").read_text(encoding="utf-8") == "fvk prompt text"

    # solutions/ — both patches including the empty one
    assert (dst / "solutions" / "solution_baseline.patch").exists()
    assert (dst / "solutions" / "solution_fvk.patch").exists()
    assert (dst / "solutions" / "solution_baseline.patch").read_bytes() == b"diff --git a/x.py b/x.py\n+fix\n"
    assert (dst / "solutions" / "solution_fvk.patch").read_bytes() == b""

    # reports/
    assert (dst / "reports" / "baseline_notes.md").read_text(encoding="utf-8") == "# Baseline Notes"
    assert (dst / "reports" / "fvk_notes.md").read_text(encoding="utf-8") == "# FVK Notes"

    # fvk/ artifacts (from .fvk_bench/artifacts/fvk/fvk/)
    assert (dst / "fvk" / "SPEC.md").read_text(encoding="utf-8") == "# Spec"
    assert (dst / "fvk" / "proof.k").read_text(encoding="utf-8") == "rule: foo"

    # transcripts/ — gzip compressed, round-trip correct
    baseline_gz = dst / "transcripts" / "baseline.jsonl.gz"
    fvk_gz = dst / "transcripts" / "fvk.jsonl.gz"
    assert baseline_gz.exists()
    assert fvk_gz.exists()

    with gzip.open(baseline_gz, "rb") as f:
        assert f.read() == BASELINE_TRANSCRIPT_CONTENT
    with gzip.open(fvk_gz, "rb") as f:
        assert f.read() == FVK_TRANSCRIPT_CONTENT

    # control arm had no session_id → no transcript file, and no transcript_missing note
    # (session_id is None → skipped, not "missing")
    assert not (dst / "transcripts" / "control.jsonl.gz").exists()


# ---------------------------------------------------------------------------
# Test 2: missing pieces tolerated
# ---------------------------------------------------------------------------

def test_harvest_missing_pieces_tolerated(tmp_path, monkeypatch):
    """Harvest succeeds with only state.json + baseline prompt; records missing transcripts."""
    tmp_home = tmp_path / "home"
    monkeypatch.setattr(Path, "home", classmethod(lambda cls: tmp_home))

    ws = tmp_path / "ws"
    ws.mkdir()
    results_dir = tmp_path / "results"

    # Minimal workspace: only state.json + baseline prompt; baseline has a session_id
    # but no transcript file exists
    fvk_bench_dir = ws / ".fvk_bench"
    fvk_bench_dir.mkdir(parents=True)
    state = _make_state()
    (fvk_bench_dir / "state.json").write_text(json.dumps(state), encoding="utf-8")
    (fvk_bench_dir / "prompts").mkdir()
    (fvk_bench_dir / "prompts" / "baseline.md").write_text("baseline only", encoding="utf-8")
    # No solutions, no artifacts, no raw envelopes, no transcripts on disk

    dst = harvest.harvest_instance(ws, RUN_ID, FAKE_INSTANCE, results_dir)

    assert dst.exists()

    manifest = json.loads((dst / "manifest.json").read_text(encoding="utf-8"))
    assert manifest["run_id"] == RUN_ID

    # transcript_missing should note the arms that had session_ids but no file found
    assert "transcript_missing" in manifest
    missing = manifest["transcript_missing"]
    assert "baseline" in missing
    assert "fvk" in missing

    # Only baseline prompt was present
    assert (dst / "prompts" / "baseline.md").exists()
    assert not (dst / "prompts" / "fvk.md").exists()

    # Absent dirs simply not created
    assert not (dst / "solutions").exists()
    assert not (dst / "reports").exists()
    assert not (dst / "fvk").exists()
    assert not (dst / "review").exists()


# ---------------------------------------------------------------------------
# Test 3: idempotent overwrite
# ---------------------------------------------------------------------------

def test_harvest_idempotent_overwrite(tmp_path, monkeypatch):
    """Calling harvest_instance twice with updated state reflects new content."""
    tmp_home = tmp_path / "home"
    monkeypatch.setattr(Path, "home", classmethod(lambda cls: tmp_home))

    ws = tmp_path / "ws"
    ws.mkdir()
    results_dir = tmp_path / "results"

    _build_fake_workspace(ws, tmp_home)

    # First harvest
    dst1 = harvest.harvest_instance(ws, RUN_ID, FAKE_INSTANCE, results_dir)
    manifest1 = json.loads((dst1 / "manifest.json").read_text(encoding="utf-8"))
    assert manifest1["arms"]["baseline"]["num_turns"] == 10

    # Mutate state.json to simulate updated data
    state = _make_state()
    state["arms"]["baseline"]["num_turns"] = 99
    (ws / ".fvk_bench" / "state.json").write_text(json.dumps(state), encoding="utf-8")

    # Second harvest
    dst2 = harvest.harvest_instance(ws, RUN_ID, FAKE_INSTANCE, results_dir)
    assert dst2 == dst1
    manifest2 = json.loads((dst2 / "manifest.json").read_text(encoding="utf-8"))
    assert manifest2["arms"]["baseline"]["num_turns"] == 99


# ---------------------------------------------------------------------------
# Test 4: write_run_manifest fields
# ---------------------------------------------------------------------------

def test_run_manifest_fields(tmp_path, monkeypatch):
    """write_run_manifest includes all required keys with correct structure."""
    results_dir = tmp_path / "results"

    # Monkeypatch subprocess.run so we don't actually call claude --version
    original_run = subprocess.run

    def fake_run(cmd, *args, **kwargs):
        if isinstance(cmd, (list, tuple)) and len(cmd) >= 2 and cmd[-1] == "--version":
            import subprocess as sp
            cr = sp.CompletedProcess(cmd, 0, stdout="9.9.9 (Claude Code)\n", stderr="")
            return cr
        return original_run(cmd, *args, **kwargs)

    monkeypatch.setattr(subprocess, "run", fake_run)

    p = harvest.write_run_manifest(RUN_ID, results_dir)

    assert p == results_dir / RUN_ID / "run_manifest.json"
    assert p.exists()

    m = json.loads(p.read_text(encoding="utf-8"))

    assert m["run_id"] == RUN_ID
    assert "created_utc" in m
    # ISO datetime check
    assert "T" in m["created_utc"]

    host = m["host"]
    assert "hostname" in host
    assert "os" in host
    assert "arch" in host
    assert "python" in host

    # claude_version from the monkeypatched subprocess
    assert m["claude_version"] == "9.9.9 (Claude Code)"

    inv = m["invocation"]
    assert inv["model"] == config.MODEL
    assert inv["effort"] == config.EFFORT
    assert inv["max_turns"] == config.MAX_TURNS
    assert inv["tools"] == config.TOOLS
    assert inv["permission_mode"] == config.PERMISSION_MODE
    assert inv["setting_sources"] == config.SETTING_SOURCES

    assert m["dataset"] == config.DATASET_NAME

    th = m["template_hashes"]
    assert set(th.keys()) == {"baseline", "fvk", "control"}

    import fvk_bench
    assert m["fvk_bench_version"] == fvk_bench.__version__

    git_info = m["git"]
    assert "repo_sha" in git_info
    # Real repo: should be a 40-hex sha
    assert re.match(r"^[0-9a-f]{40}$", git_info["repo_sha"]), f"not a sha: {git_info['repo_sha']!r}"

    submodules = git_info["submodules"]
    assert isinstance(submodules, dict)
    # Both third_party submodules should appear
    assert "third_party/swebench-fvk-reproducibility" in submodules
    assert "third_party/formal-verification-kit" in submodules


def test_run_manifest_codex_fields(tmp_path, monkeypatch):
    """Codex manifests record the Codex invocation, not Claude's."""
    results_dir = tmp_path / "results"
    original_run = subprocess.run

    def fake_run(cmd, *args, **kwargs):
        if isinstance(cmd, (list, tuple)) and cmd[:2] == ["/opt/codex", "--version"]:
            import subprocess as sp
            return sp.CompletedProcess(cmd, 0, stdout="codex-cli 0.140.0-alpha.2\n", stderr="")
        return original_run(cmd, *args, **kwargs)

    monkeypatch.setattr(subprocess, "run", fake_run)

    p = harvest.write_run_manifest(
        RUN_ID,
        results_dir,
        extra={"agent": "codex", "codex_bin": "/opt/codex", "max_parallel": 2},
    )

    m = json.loads(p.read_text(encoding="utf-8"))
    assert m["agent"] == "codex"
    assert m["codex_version"] == "codex-cli 0.140.0-alpha.2"
    assert "claude_version" not in m
    assert m["invocation"] == {
        "model": config.CODEX_MODEL,
        "effort": config.CODEX_EFFORT,
        "sandbox": config.CODEX_SANDBOX,
        "max_turns": config.MAX_TURNS,
    }


# ---------------------------------------------------------------------------
# Test 5: harvested files not gitignored in the real results dir
# ---------------------------------------------------------------------------

def test_harvested_files_not_gitignored(tmp_path, monkeypatch):
    """Patch files and transcript gz files inside results/ are NOT gitignored."""
    tmp_home = tmp_path / "home"
    monkeypatch.setattr(Path, "home", classmethod(lambda cls: tmp_home))

    run_id = "test-gitignore-probe"
    ws = tmp_path / "ws"
    ws.mkdir()

    # Build minimal workspace with a patch and transcript so harvest creates them
    fvk_bench_dir = ws / ".fvk_bench"
    fvk_bench_dir.mkdir(parents=True)
    state = _make_state()
    (fvk_bench_dir / "state.json").write_text(json.dumps(state), encoding="utf-8")
    solutions_dir = fvk_bench_dir / "solutions"
    solutions_dir.mkdir()
    (solutions_dir / "solution_baseline.patch").write_bytes(b"diff --git a/x.py b/x.py\n")
    _plant_transcript(ws, tmp_home, SID_BASELINE, BASELINE_TRANSCRIPT_CONTENT)

    dst = harvest.harvest_instance(ws, run_id, FAKE_INSTANCE, config.RESULTS_DIR)

    patch_file = dst / "solutions" / "solution_baseline.patch"
    gz_file = dst / "transcripts" / "baseline.jsonl.gz"

    assert patch_file.exists(), "patch file was not created by harvest"
    assert gz_file.exists(), "gz transcript was not created by harvest"

    try:
        # git check-ignore exits 0 if file IS ignored, 1 if NOT ignored
        result_patch = subprocess.run(
            ["git", "check-ignore", "-q", str(patch_file)],
            cwd=str(config.REPO_ROOT),
            capture_output=True,
        )
        assert result_patch.returncode == 1, (
            f"solution_baseline.patch is gitignored (exit {result_patch.returncode})"
        )

        result_gz = subprocess.run(
            ["git", "check-ignore", "-q", str(gz_file)],
            cwd=str(config.REPO_ROOT),
            capture_output=True,
        )
        assert result_gz.returncode == 1, (
            f"baseline.jsonl.gz is gitignored (exit {result_gz.returncode})"
        )
    finally:
        import shutil
        run_dir = config.RESULTS_DIR / run_id
        if run_dir.exists():
            shutil.rmtree(run_dir)

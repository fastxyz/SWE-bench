"""Tests for fvk_bench.arms — written before implementation (TDD).

``run_instance`` tests drive the real orchestration against the conftest
fixture repo and the fake claude binary. Because the runner scrubs the child
environment, scenario/edits selection is baked into a tiny wrapper script that
exports ``FAKE_*`` before exec'ing the fake (the ``_scenario_bin`` pattern from
test_claude_runner.py).

The fake claude drops byproducts into its cwd — the workspace root — before
exec'ing the edits script: ``fake_claude_capture.json`` (overwritten per
invocation) and ``fake_claude_invocations.log`` (appended). Those files live in
the *hashed* core tree, so they would register as cross-arm drift and trip the
contamination guard. Every dispatching edits script therefore starts by
relocating them into the hash-excluded ``.fvk_bench/fake/`` area; tests read
the merged invocation log from there (plus any un-relocated root log, e.g.
when a failing scenario never runs the edits script).
"""

import json
import subprocess
import uuid
from pathlib import Path

import pytest

import fvk_bench.arms as arms_mod
import fvk_bench.claude_runner as claude_runner
import fvk_bench.scaffold as scaffold
from fvk_bench import config

_LOG_MARKER = "FAKE_CLAUDE_INVOKED "

# One edits script serves all three arms by inspecting workspace state — the
# orchestrator's deterministic arm order (baseline -> fvk -> control) makes the
# dispatch unambiguous: no baseline notes yet => baseline; fvk_materials staged
# => fvk; otherwise => control.
_DISPATCH_EDITS = '''
from pathlib import Path

ws = Path.cwd()

# Relocate fake-claude byproducts (already written into cwd by the fake before
# this script runs) into the hash-excluded .fvk_bench/ area so they cannot
# perturb the orchestrator's core tree hash between arms.
fake_dir = ws / ".fvk_bench" / "fake"
fake_dir.mkdir(parents=True, exist_ok=True)
log = ws / "fake_claude_invocations.log"
if log.exists():
    with open(fake_dir / "invocations.log", "a", encoding="utf-8") as out:
        out.write(log.read_text(encoding="utf-8"))
    log.unlink()
cap = ws / "fake_claude_capture.json"
if cap.exists():
    cap.unlink()

if not (ws / "reports" / "baseline_notes.md").exists():
    # baseline arm
    with open(ws / "repo" / "lib.py", "a", encoding="utf-8") as fh:
        fh.write("# baseline edit\\n")
    (ws / "reports" / "baseline_notes.md").write_text("v1 notes\\n", encoding="utf-8")
elif (ws / "fvk_materials").exists():
    # fvk arm
    for name in ("SPEC.md", "PROPERTIES.md", "AUDIT.md", "PROOFS.md", "GAPS.md"):
        (ws / "fvk" / name).write_text(name + "\\n", encoding="utf-8")
    with open(ws / "repo" / "lib.py", "a", encoding="utf-8") as fh:
        fh.write("# fvk edit\\n")
    (ws / "reports" / "fvk_notes.md").write_text("fvk notes\\n", encoding="utf-8")
{fvk_extra}
else:
    # control arm
    (ws / "review").mkdir(exist_ok=True)
    (ws / "review" / "FINDINGS.md").write_text("findings\\n", encoding="utf-8")
    (ws / "reports" / "control_notes.md").write_text("control notes\\n", encoding="utf-8")
'''

# Baseline-only edits: create a brand-new repo file (exercises "new file mode"
# in the extracted patch). Used with arms=("baseline",) so no cross-arm hash
# comparison ever happens and byproduct relocation is unnecessary.
_NEWFILE_EDITS = '''
from pathlib import Path

ws = Path.cwd()
(ws / "repo" / "newmod.py").write_text("VALUE = 1\\n", encoding="utf-8")
(ws / "reports" / "baseline_notes.md").write_text("v1 notes\\n", encoding="utf-8")
'''


def _wrapper_bin(
    tmp_path: Path,
    fake_claude_bin: Path,
    *,
    scenario: str = "ok",
    edits: Path | None = None,
) -> Path:
    """Wrap the fake claude so FAKE_* settings survive the runner's env scrub."""
    wrapper = tmp_path / "scenario_bin" / "claude"
    wrapper.parent.mkdir(parents=True, exist_ok=True)
    lines = ["#!/bin/sh", f"export FAKE_CLAUDE_SCENARIO={scenario}"]
    if edits is not None:
        lines.append(f'export FAKE_CLAUDE_EDITS="{edits}"')
    lines.append(f'exec "{fake_claude_bin}" "$@"')
    wrapper.write_text("\n".join(lines) + "\n", encoding="utf-8")
    wrapper.chmod(0o755)
    return wrapper


def _write_dispatch_edits(tmp_path: Path, fvk_extra: str = "    pass") -> Path:
    script = tmp_path / "edits.py"
    script.write_text(_DISPATCH_EDITS.format(fvk_extra=fvk_extra), encoding="utf-8")
    return script


def _invocation_argvs(ws: Path) -> list[list[str]]:
    """All fake-claude argvs, in order: relocated log first, then root log."""
    text = ""
    relocated = ws / ".fvk_bench" / "fake" / "invocations.log"
    if relocated.exists():
        text += relocated.read_text(encoding="utf-8")
    root_log = ws / "fake_claude_invocations.log"
    if root_log.exists():
        text += root_log.read_text(encoding="utf-8")
    return [
        json.loads(line[len(_LOG_MARKER):])
        for line in text.splitlines()
        if line.startswith(_LOG_MARKER)
    ]


def _git_out(args: list[str], cwd: Path) -> str:
    proc = subprocess.run(
        ["git", *args], cwd=cwd, check=True, capture_output=True, text=True
    )
    return proc.stdout.strip()


@pytest.fixture()
def local_clone_url(fixture_remote_repo, monkeypatch):
    """Point scaffold's clone-url hook at the local fixture remote."""
    remote_path, _ = fixture_remote_repo
    monkeypatch.setattr(scaffold, "_clone_url", lambda repo: f"file://{remote_path}")


@pytest.fixture()
def make_ws(local_clone_url, fixture_instance, tmp_path):
    """Build a real scaffolded workspace for unit tests of the git helpers."""

    def _make() -> Path:
        mirror = scaffold.ensure_mirror(fixture_instance.repo, tmp_path / "cache")
        return scaffold.create_workspace(
            "run-t", fixture_instance, tmp_path / "ws_root", mirror
        )

    return _make


def _run(fixture_instance, tmp_path, bin_path: Path, **kwargs) -> dict:
    return arms_mod.run_instance(
        "run-1",
        fixture_instance,
        tmp_path / "ws_root",
        claude_bin=str(bin_path),
        timeout=60,
        cache_dir=tmp_path / "cache",
        **kwargs,
    )


def _ws(tmp_path: Path, fixture_instance) -> Path:
    return tmp_path / "ws_root" / "run-1" / fixture_instance.instance_id


# ---------------------------------------------------------------------------
# 1. happy path: 3 arms complete, patches cumulative/byte-equal, scrub holds
# ---------------------------------------------------------------------------

def test_happy_path_full_run(local_clone_url, fixture_instance, fake_claude_bin, tmp_path):
    edits = _write_dispatch_edits(tmp_path)
    bin_path = _wrapper_bin(tmp_path, fake_claude_bin, edits=edits)

    state = _run(fixture_instance, tmp_path, bin_path)
    ws = _ws(tmp_path, fixture_instance)

    assert {a: state["arms"][a]["status"] for a in config.ARMS} == {
        "baseline": "completed", "fvk": "completed", "control": "completed",
    }
    for arm in config.ARMS:
        arm_state = state["arms"][arm]
        assert arm_state["attempts"] == 1
        assert arm_state["started_at"] and arm_state["ended_at"]
        assert arm_state["num_turns"] == 7
        assert arm_state["duration_seconds"] > 0
        # No transcript exists for fake sessions: audit recorded as not-found.
        assert arm_state["audit"] == {"ok": None, "note": "transcript_not_found"}

    # 3 distinct session ids; baseline's pre-generated id is a valid uuid4.
    sids = [state["arms"][arm]["session_id"] for arm in config.ARMS]
    assert all(sids) and len(set(sids)) == 3
    assert uuid.UUID(state["baseline_session_id"]).version == 4
    assert state["arms"]["baseline"]["session_id"] == state["baseline_session_id"]

    # Patches: baseline non-empty, fvk cumulative, control byte-equal baseline.
    sol = ws / ".fvk_bench" / "solutions"
    baseline_patch = (sol / "solution_baseline.patch").read_bytes()
    fvk_patch = (sol / "solution_fvk.patch").read_bytes()
    control_patch = (sol / "solution_control.patch").read_bytes()
    assert baseline_patch and b"lib.py" in baseline_patch
    assert b"# baseline edit" in fvk_patch and b"# fvk edit" in fvk_patch
    assert control_patch == baseline_patch

    # Scrub: no fvk traces remain in the workspace...
    assert not (ws / "fvk_materials").exists()
    assert not (ws / "fvk").exists()
    assert not (ws / "reports" / "fvk_notes.md").exists()
    # ...but the snapshots survived the scrub.
    artifacts = ws / ".fvk_bench" / "artifacts"
    assert (artifacts / "baseline" / "reports" / "baseline_notes.md").is_file()
    assert (artifacts / "fvk" / "fvk" / "SPEC.md").is_file()
    assert (artifacts / "fvk" / "reports" / "fvk_notes.md").is_file()
    assert (artifacts / "control" / "review" / "FINDINGS.md").is_file()

    assert state["core_hash_post_baseline"]

    # Exactly 3 invocations; the two forks resumed the frozen baseline session.
    argvs = _invocation_argvs(ws)
    assert len(argvs) == 3
    baseline_sid = state["baseline_session_id"]
    assert argvs[0][argvs[0].index("--session-id") + 1] == baseline_sid
    for argv in argvs[1:]:
        assert argv[argv.index("--resume") + 1] == baseline_sid
        assert "--fork-session" in argv
        assert "--session-id" not in argv


# ---------------------------------------------------------------------------
# 2. brand-new file shows up as "new file mode" in the extracted patch
# ---------------------------------------------------------------------------

def test_new_file_in_patch(local_clone_url, fixture_instance, fake_claude_bin, tmp_path):
    edits = tmp_path / "edits.py"
    edits.write_text(_NEWFILE_EDITS, encoding="utf-8")
    bin_path = _wrapper_bin(tmp_path, fake_claude_bin, edits=edits)

    state = _run(fixture_instance, tmp_path, bin_path, arms=("baseline",))

    assert state["arms"]["baseline"]["status"] == "completed"
    patch = (
        _ws(tmp_path, fixture_instance)
        / ".fvk_bench" / "solutions" / "solution_baseline.patch"
    ).read_bytes()
    assert b"new file mode" in patch
    assert b"newmod.py" in patch


# ---------------------------------------------------------------------------
# 3. stray fvk write outside the scrubbed paths blocks the control arm
# ---------------------------------------------------------------------------

def test_contamination_guard_blocks_control(
    local_clone_url, fixture_instance, fake_claude_bin, tmp_path
):
    stray = '    (ws / "reports" / "extra.txt").write_text("stray\\n", encoding="utf-8")'
    edits = _write_dispatch_edits(tmp_path, fvk_extra=stray)
    bin_path = _wrapper_bin(tmp_path, fake_claude_bin, edits=edits)

    state = _run(fixture_instance, tmp_path, bin_path)
    ws = _ws(tmp_path, fixture_instance)

    assert state["arms"]["baseline"]["status"] == "completed"
    assert state["arms"]["fvk"]["status"] == "completed"
    assert state["arms"]["control"]["status"] == "failed"
    assert state["arms"]["control"]["reason"] == "contaminated_workspace"

    # The control session was never launched: only baseline + fvk invocations.
    assert len(_invocation_argvs(ws)) == 2
    assert state["arms"]["control"]["session_id"] is None
    assert state["arms"]["control"]["attempts"] == 0


# ---------------------------------------------------------------------------
# 4. baseline failure skips both review arms without launching them
# ---------------------------------------------------------------------------

def test_baseline_failure_skips_rest(
    local_clone_url, fixture_instance, fake_claude_bin, tmp_path
):
    bin_path = _wrapper_bin(tmp_path, fake_claude_bin, scenario="exit2")

    state = _run(fixture_instance, tmp_path, bin_path)
    ws = _ws(tmp_path, fixture_instance)

    baseline = state["arms"]["baseline"]
    assert baseline["status"] == "failed"
    assert baseline["reason"]  # exact error text is claude_runner's business
    assert baseline["attempts"] == 1
    for arm in ("fvk", "control"):
        assert state["arms"][arm]["status"] == "skipped"
        assert state["arms"][arm]["reason"] == "baseline_failed"
        assert state["arms"][arm]["attempts"] == 0

    assert len(_invocation_argvs(ws)) == 1


# ---------------------------------------------------------------------------
# 5. re-running a finished instance is a no-op (crash-resumable state)
# ---------------------------------------------------------------------------

def test_rerun_skips_completed(local_clone_url, fixture_instance, fake_claude_bin, tmp_path):
    edits = _write_dispatch_edits(tmp_path)
    bin_path = _wrapper_bin(tmp_path, fake_claude_bin, edits=edits)

    first = _run(fixture_instance, tmp_path, bin_path)
    ws = _ws(tmp_path, fixture_instance)
    argvs_before = _invocation_argvs(ws)

    second = _run(fixture_instance, tmp_path, bin_path)

    assert _invocation_argvs(ws) == argvs_before  # zero new invocations
    assert second == first  # statuses, ids, timestamps — all unchanged


# ---------------------------------------------------------------------------
# 6. core_tree_hash: exclusions, sensitivity, symlinks
# ---------------------------------------------------------------------------

def test_core_tree_hash_excludes(tmp_path):
    ws = tmp_path / "ws"
    (ws / "repo" / ".git").mkdir(parents=True)
    (ws / "reports").mkdir(parents=True)
    (ws / "repo" / "lib.py").write_text("x = 1\n", encoding="utf-8")
    (ws / "repo" / ".git" / "HEAD").write_text("ref: refs/heads/main\n", encoding="utf-8")
    (ws / "reports" / "x.md").write_text("hi\n", encoding="utf-8")

    h0 = arms_mod.core_tree_hash(ws)
    assert h0 == arms_mod.core_tree_hash(ws)  # deterministic

    # Changes under every excluded subtree leave the hash untouched.
    for rel in (
        ".fvk_bench/state.json",
        ".fvk_bench/fake/invocations.log",
        "fvk/SPEC.md",
        "fvk_materials/README.md",
        "review/FINDINGS.md",
        "repo/.git/index",
    ):
        path = ws / rel
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text("noise\n", encoding="utf-8")
    assert arms_mod.core_tree_hash(ws) == h0

    # Core changes are detected: repo file content...
    (ws / "repo" / "lib.py").write_text("x = 2\n", encoding="utf-8")
    h1 = arms_mod.core_tree_hash(ws)
    assert h1 != h0

    # ...reports content...
    (ws / "reports" / "x.md").write_text("changed\n", encoding="utf-8")
    h2 = arms_mod.core_tree_hash(ws)
    assert h2 != h1

    # ...and brand-new files at the workspace root.
    (ws / "stray.txt").write_text("stray\n", encoding="utf-8")
    h3 = arms_mod.core_tree_hash(ws)
    assert h3 != h2

    # Symlinks are hashed by their target string (works for dangling links).
    (ws / "link").symlink_to("no-such-target-1")
    h4 = arms_mod.core_tree_hash(ws)
    assert h4 != h3
    (ws / "link").unlink()
    (ws / "link").symlink_to("no-such-target-2")
    assert arms_mod.core_tree_hash(ws) != h4


# ---------------------------------------------------------------------------
# 7. stage_fvk copies exactly the pinned materials from the real submodule
# ---------------------------------------------------------------------------

def test_stage_fvk_copies_8_files(make_ws):
    ws = make_ws()

    arms_mod.stage_fvk(ws)

    materials = ws / "fvk_materials"
    found = sorted(
        p.relative_to(materials).as_posix()
        for p in materials.rglob("*")
        if p.is_file()
    )
    assert found == sorted(config.FVK_MATERIALS_FILES)
    # Byte-identical to the real submodule source.
    assert (materials / "README.md").read_bytes() == (
        config.FVK_SUBMODULE / "README.md"
    ).read_bytes()
    # fvk/ output dir exists and starts empty.
    assert (ws / "fvk").is_dir()
    assert list((ws / "fvk").iterdir()) == []


# ---------------------------------------------------------------------------
# 8. extract_patch: empty diff -> empty file; staging always restored
# ---------------------------------------------------------------------------

def test_extract_patch_empty_when_no_changes(make_ws):
    ws = make_ws()

    patch = arms_mod.extract_patch(ws, "baseline")

    assert patch == ws / ".fvk_bench" / "solutions" / "solution_baseline.patch"
    assert patch.read_bytes() == b""


def test_extract_patch_unstages_afterwards(make_ws):
    ws = make_ws()
    (ws / "repo" / "foo.txt").write_text("hi\n", encoding="utf-8")

    patch = arms_mod.extract_patch(ws, "fvk")

    assert b"foo.txt" in patch.read_bytes()
    # git reset ran: the file is back to untracked, nothing left staged.
    assert _git_out(["status", "--porcelain"], cwd=ws / "repo") == "?? foo.txt"


# ---------------------------------------------------------------------------
# 9. a dirty transcript flips a completed arm to failed(contaminated_session)
# ---------------------------------------------------------------------------

def test_dirty_transcript_marks_contaminated_session(
    local_clone_url, fixture_instance, fake_claude_bin, tmp_path, monkeypatch
):
    transcript = tmp_path / "dirty.jsonl"
    transcript.write_text(
        json.dumps(
            {
                "type": "assistant",
                "message": {
                    "content": [{"type": "tool_use", "name": "Bash", "input": {}}]
                },
            }
        )
        + "\n",
        encoding="utf-8",
    )
    monkeypatch.setattr(
        claude_runner, "transcript_path", lambda ws, sid: transcript
    )

    edits = tmp_path / "edits.py"
    edits.write_text(_NEWFILE_EDITS, encoding="utf-8")
    bin_path = _wrapper_bin(tmp_path, fake_claude_bin, edits=edits)

    state = _run(fixture_instance, tmp_path, bin_path, arms=("baseline",))

    baseline = state["arms"]["baseline"]
    assert baseline["status"] == "failed"
    assert baseline["reason"] == "contaminated_session"
    assert baseline["audit"]["ok"] is False
    assert baseline["audit"]["violations"] == ["Bash"]
    # Artifacts are kept: the patch was extracted before the audit verdict.
    patch = (
        _ws(tmp_path, fixture_instance)
        / ".fvk_bench" / "solutions" / "solution_baseline.patch"
    )
    assert patch.exists() and b"newmod.py" in patch.read_bytes()

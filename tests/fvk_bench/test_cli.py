"""Tests for fvk_bench.cli — written before implementation (TDD).

The ``run`` happy path is a true end-to-end drive: fake claude (with the
dispatching edits wrapper from test_arms.py), the conftest fixture remote,
a tmp workspace root and a tmp results dir (config.RESULTS_DIR monkeypatched)
— only ``load_instances`` is faked, because instances.json is vendored in a
later task. Heavy externals (official harness, real canary) are monkeypatched
at the function boundary.
"""

import dataclasses
import json
import re
import threading
from pathlib import Path

import pytest

import fvk_bench.arms as arms_mod
import fvk_bench.cli as cli
import fvk_bench.doctor as doctor_mod
import fvk_bench.evaluate as evaluate_mod
import fvk_bench.harvest as harvest_mod
import fvk_bench.instances as instances_mod
import fvk_bench.scaffold as scaffold
from fvk_bench import batches, config

# Same dispatch logic as test_arms.py: relocate fake-claude byproducts out of
# the hashed core tree, then edit per arm (order makes dispatch unambiguous).
_DISPATCH_EDITS = '''
from pathlib import Path

ws = Path.cwd()

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
    with open(ws / "repo" / "lib.py", "a", encoding="utf-8") as fh:
        fh.write("# baseline edit\\n")
    (ws / "reports" / "baseline_notes.md").write_text("v1 notes\\n", encoding="utf-8")
elif (ws / "fvk_materials").exists():
    for name in ("SPEC.md", "PROPERTIES.md", "AUDIT.md", "PROOFS.md", "GAPS.md"):
        (ws / "fvk" / name).write_text(name + "\\n", encoding="utf-8")
    with open(ws / "repo" / "lib.py", "a", encoding="utf-8") as fh:
        fh.write("# fvk edit\\n")
    (ws / "reports" / "fvk_notes.md").write_text("fvk notes\\n", encoding="utf-8")
else:
    (ws / "review").mkdir(exist_ok=True)
    (ws / "review" / "FINDINGS.md").write_text("findings\\n", encoding="utf-8")
    (ws / "reports" / "control_notes.md").write_text("control notes\\n", encoding="utf-8")
'''


def _wrapper_bin(
    tmp_path: Path,
    fake_claude_bin: Path,
    *,
    scenario: str = "ok",
    edits: Path | None = None,
) -> Path:
    wrapper = tmp_path / "scenario_bin" / "claude"
    wrapper.parent.mkdir(parents=True, exist_ok=True)
    lines = ["#!/bin/sh", f"export FAKE_CLAUDE_SCENARIO={scenario}"]
    if edits is not None:
        lines.append(f'export FAKE_CLAUDE_EDITS="{edits}"')
    lines.append(f'exec "{fake_claude_bin}" "$@"')
    wrapper.write_text("\n".join(lines) + "\n", encoding="utf-8")
    wrapper.chmod(0o755)
    return wrapper


@pytest.fixture()
def cli_env(fixture_remote_repo, fixture_instance, tmp_path, monkeypatch) -> Path:
    """Hermetic CLI environment: local remote, fake loader, tmp results dir."""
    remote_path, _ = fixture_remote_repo
    monkeypatch.setattr(scaffold, "_clone_url", lambda repo: f"file://{remote_path}")
    monkeypatch.setattr(
        instances_mod,
        "load_instances",
        lambda *a, **k: {fixture_instance.instance_id: fixture_instance},
    )
    results_dir = tmp_path / "results"
    monkeypatch.setattr(config, "RESULTS_DIR", results_dir)
    # write_run_manifest probes `claude --version`; point it at a missing
    # binary so the probe fails cleanly instead of touching the host or
    # letting the fake write capture files into the test runner's cwd.
    monkeypatch.setenv("FVK_BENCH_CLAUDE_BIN", "/nonexistent/claude")
    return results_dir


# ---------------------------------------------------------------------------
# run
# ---------------------------------------------------------------------------

def test_run_happy_end_to_end(
    cli_env, fixture_instance, fake_claude_bin, tmp_path, capsys
):
    edits = tmp_path / "edits.py"
    edits.write_text(_DISPATCH_EDITS, encoding="utf-8")
    bin_path = _wrapper_bin(tmp_path, fake_claude_bin, edits=edits)
    ws_root = tmp_path / "wsroot"

    rc = cli.main([
        "run",
        "--instances", fixture_instance.instance_id,
        "--run-id", "t",
        "--claude-bin", str(bin_path),
        "--workspace-root", str(ws_root),
        "--timeout", "60",
    ])

    assert rc == 0
    dst = cli_env / "t" / fixture_instance.instance_id
    assert (dst / "manifest.json").is_file()
    manifest = json.loads((dst / "manifest.json").read_text(encoding="utf-8"))
    assert {a: manifest["arms"][a]["status"] for a in config.ARMS} == {
        "baseline": "completed", "fvk": "completed", "control": "completed",
    }
    for arm in config.ARMS:
        assert (dst / "solutions" / f"solution_{arm}.patch").is_file()
    assert (cli_env / "t" / "run_manifest.json").is_file()
    # The workspace (and its repo cache) stayed under the chosen root.
    assert (ws_root / "t" / fixture_instance.instance_id / "repo").is_dir()
    assert (ws_root / "cache" / "repos").is_dir()

    out = capsys.readouterr().out
    assert "baseline=completed" in out
    assert "fvk=completed" in out
    assert "control=completed" in out


def test_run_failure_exits_1(cli_env, fixture_instance, fake_claude_bin, tmp_path, capsys):
    bin_path = _wrapper_bin(tmp_path, fake_claude_bin, scenario="exit2")

    rc = cli.main([
        "run",
        "--instances", fixture_instance.instance_id,
        "--run-id", "tf",
        "--claude-bin", str(bin_path),
        "--workspace-root", str(tmp_path / "wsroot"),
        "--timeout", "60",
    ])

    assert rc == 1  # baseline failed, fvk/control skipped: nothing completed
    out = capsys.readouterr().out
    assert "baseline=failed" in out
    assert "skipped" in out
    # Results were still harvested for forensics.
    assert (cli_env / "tf" / fixture_instance.instance_id / "manifest.json").is_file()


def test_run_partial_exits_2(
    cli_env, fixture_instance, fake_claude_bin, tmp_path, monkeypatch, capsys
):
    good = fixture_instance
    bad = dataclasses.replace(
        good, instance_id="demo__demo-2", base_commit="0" * 40
    )  # commit that does not exist → scaffolding RuntimeError
    monkeypatch.setattr(
        instances_mod,
        "load_instances",
        lambda *a, **k: {good.instance_id: good, bad.instance_id: bad},
    )
    edits = tmp_path / "edits.py"
    edits.write_text(_DISPATCH_EDITS, encoding="utf-8")
    bin_path = _wrapper_bin(tmp_path, fake_claude_bin, edits=edits)

    rc = cli.main([
        "run",
        "--instances", good.instance_id, bad.instance_id,
        "--run-id", "tp",
        "--claude-bin", str(bin_path),
        "--workspace-root", str(tmp_path / "wsroot"),
        "--timeout", "60",
    ])

    assert rc == 2  # one instance fully completed, the other errored
    out = capsys.readouterr().out
    assert "baseline=completed" in out
    assert "error" in out


def test_run_orchestration_error_stub_in_scores(
    cli_env, fixture_instance, monkeypatch, tmp_path, capsys
):
    """An instance whose orchestration raises still appears in the scores table."""
    def boom(*args, **kwargs):
        raise RuntimeError("mirror clone failed")

    monkeypatch.setattr(arms_mod, "run_instance", boom)

    rc = cli.main([
        "run",
        "--instances", fixture_instance.instance_id,
        "--run-id", "te",
        "--workspace-root", str(tmp_path / "wsroot"),
    ])

    assert rc == 1  # nothing completed → nonzero
    manifest_path = cli_env / "te" / fixture_instance.instance_id / "manifest.json"
    manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    assert manifest["run_id"] == "te"
    assert manifest["instance_id"] == fixture_instance.instance_id
    assert manifest["orchestration_error"] == "mirror clone failed"
    assert manifest["arms"] == {
        arm: {"status": "failed", "reason": "orchestration_error"}
        for arm in config.ARMS
    }
    assert "error: mirror clone failed" in capsys.readouterr().out

    # The stub surfaces through the report pipeline like any other failed arm.
    assert cli.main(["report", "--run-id", "te"]) == 0
    md = (cli_env / "te" / "scores.md").read_text(encoding="utf-8")
    row = next(
        line for line in md.splitlines()
        if line.startswith(f"| {fixture_instance.instance_id} ")
    )
    assert row.count("failed(orchestration_error)") == len(config.ARMS)


def test_run_orchestration_error_keeps_existing_manifest(
    cli_env, fixture_instance, monkeypatch, tmp_path
):
    """A manifest harvested by an earlier attempt is never clobbered by the stub."""
    inst_dir = cli_env / "tk" / fixture_instance.instance_id
    inst_dir.mkdir(parents=True)
    existing = {
        "run_id": "tk",
        "instance_id": fixture_instance.instance_id,
        "arms": {"baseline": {"status": "completed", "reason": None}},
    }
    (inst_dir / "manifest.json").write_text(json.dumps(existing), encoding="utf-8")

    def boom(*args, **kwargs):
        raise OSError("disk full")

    monkeypatch.setattr(arms_mod, "run_instance", boom)

    rc = cli.main([
        "run",
        "--instances", fixture_instance.instance_id,
        "--run-id", "tk",
        "--workspace-root", str(tmp_path / "wsroot"),
    ])

    assert rc == 1
    on_disk = json.loads((inst_dir / "manifest.json").read_text(encoding="utf-8"))
    assert on_disk == existing  # no orchestration_error stub written over it


def test_run_unknown_instance_id(cli_env, capsys):
    rc = cli.main(["run", "--instances", "nope__nope-1", "--run-id", "tx"])

    assert rc == 1
    assert "nope__nope-1" in capsys.readouterr().out
    assert not (cli_env / "tx").exists()


def test_run_unknown_arm(cli_env, fixture_instance, capsys):
    rc = cli.main([
        "run", "--instances", fixture_instance.instance_id,
        "--run-id", "ty", "--arms", "baseline,bogus",
    ])

    assert rc == 1
    assert "bogus" in capsys.readouterr().out


def test_default_run_id_shape():
    assert re.fullmatch(r"\d{8}T\d{6}Z-.+", cli._default_run_id())


# ---------------------------------------------------------------------------
# run: batch selection + parallel execution
# ---------------------------------------------------------------------------

def _completed_state() -> dict:
    return {
        "arms": {
            arm: {"status": "completed", "reason": None} for arm in config.ARMS
        }
    }


def _fake_45_instances(fixture_instance, monkeypatch) -> dict:
    """45 cheap fixture clones whose ids are the real submodule ids."""
    insts = {
        iid: dataclasses.replace(fixture_instance, instance_id=iid)
        for iid in instances_mod.submodule_instance_ids()
    }
    monkeypatch.setattr(instances_mod, "load_instances", lambda *a, **k: insts)
    return insts


def test_run_batch_selection(cli_env, fixture_instance, monkeypatch, tmp_path):
    _fake_45_instances(fixture_instance, monkeypatch)
    dispatched: list[str] = []
    harvested: list[str] = []

    def fake_run_instance(run_id, inst, ws_root, **kwargs):
        dispatched.append(inst.instance_id)
        return _completed_state()

    monkeypatch.setattr(arms_mod, "run_instance", fake_run_instance)
    monkeypatch.setattr(
        harvest_mod,
        "harvest_instance",
        lambda ws, rid, inst, results_dir=None: harvested.append(inst.instance_id),
    )

    rc = cli.main([
        "run", "--batch", "batch5", "--run-id", "t",
        "--workspace-root", str(tmp_path / "wsroot"),
    ])

    assert rc == 0
    assert dispatched == list(batches.BATCHES["batch5"])  # exactly those 9, in order
    assert harvested == dispatched


def test_run_rejects_batch_with_instances(cli_env, capsys):
    with pytest.raises(SystemExit) as exc_info:
        cli.main([
            "run", "--instances", "demo__demo-1", "--batch", "batch1",
            "--run-id", "t",
        ])

    assert exc_info.value.code == 2
    assert "not allowed with" in capsys.readouterr().err


def test_run_max_parallel_rolling(cli_env, fixture_instance, monkeypatch, tmp_path):
    """With --max-parallel 2 the first two instances provably run concurrently."""
    insts = {
        iid: dataclasses.replace(fixture_instance, instance_id=iid)
        for iid in ("demo__demo-1", "demo__demo-2", "demo__demo-3")
    }
    monkeypatch.setattr(instances_mod, "load_instances", lambda *a, **k: insts)

    barrier = threading.Barrier(2, timeout=10)
    calls: list[tuple[str, str]] = []
    calls_lock = threading.Lock()

    def fake_run_instance(run_id, inst, ws_root, **kwargs):
        with calls_lock:
            calls.append((inst.instance_id, threading.current_thread().name))
            position = len(calls)
        if position <= 2:
            # Both of the first two calls must be in flight at once or this
            # times out, breaks the barrier, and the run exits non-zero.
            barrier.wait()
        return _completed_state()

    monkeypatch.setattr(arms_mod, "run_instance", fake_run_instance)
    harvested: list[str] = []
    monkeypatch.setattr(
        harvest_mod,
        "harvest_instance",
        lambda ws, rid, inst, results_dir=None: harvested.append(inst.instance_id),
    )

    rc = cli.main([
        "run", "--instances", *insts, "--run-id", "t",
        "--workspace-root", str(tmp_path / "wsroot"),
        "--max-parallel", "2",
    ])

    assert rc == 0
    assert not barrier.broken, "first two instances never overlapped"
    assert calls[0][1] != calls[1][1], "first two calls must run on distinct threads"
    assert sorted(iid for iid, _ in calls) == sorted(insts)
    assert sorted(harvested) == sorted(insts)


def test_run_max_parallel_records_manifest(
    cli_env, fixture_instance, monkeypatch, tmp_path
):
    monkeypatch.setattr(arms_mod, "run_instance", lambda *a, **k: _completed_state())
    monkeypatch.setattr(harvest_mod, "harvest_instance", lambda *a, **k: None)

    rc = cli.main([
        "run", "--instances", fixture_instance.instance_id, "--run-id", "t",
        "--workspace-root", str(tmp_path / "wsroot"),
        "--max-parallel", "3",
    ])

    assert rc == 0
    manifest = json.loads(
        (cli_env / "t" / "run_manifest.json").read_text(encoding="utf-8")
    )
    assert manifest["max_parallel"] == 3


def test_run_records_requested_arms_and_instance_set(
    cli_env, fixture_instance, monkeypatch, tmp_path
):
    monkeypatch.setattr(arms_mod, "run_instance", lambda *a, **k: _completed_state())
    monkeypatch.setattr(harvest_mod, "harvest_instance", lambda *a, **k: None)

    rc = cli.main([
        "run",
        "--instances", fixture_instance.instance_id,
        "--run-id", "t",
        "--workspace-root", str(tmp_path / "wsroot"),
        "--arms", "baseline,fvk",
        "--max-parallel", "3",
    ])

    assert rc == 0
    manifest = json.loads(
        (cli_env / "t" / "run_manifest.json").read_text(encoding="utf-8")
    )
    assert manifest["arms"] == ["baseline", "fvk"]
    assert manifest["instance_set"] == "fvk45"
    assert manifest["max_parallel"] == 3


def test_run_prewarms_mirrors_once(cli_env, fixture_instance, monkeypatch, tmp_path):
    """One sequential ensure_mirror per unique repo, before any run_instance."""
    insts = {
        iid: dataclasses.replace(fixture_instance, instance_id=iid)
        for iid in ("demo__demo-1", "demo__demo-2", "demo__demo-3")
    }
    monkeypatch.setattr(instances_mod, "load_instances", lambda *a, **k: insts)

    events: list[tuple] = []
    ws_root = tmp_path / "wsroot"

    def fake_ensure_mirror(repo, cache_dir):
        events.append(("mirror", repo, Path(cache_dir)))
        return Path(cache_dir) / "demo__demo.git"

    def fake_run_instance(run_id, inst, ws_root, **kwargs):
        events.append(("run", inst.instance_id))
        return _completed_state()

    monkeypatch.setattr(scaffold, "ensure_mirror", fake_ensure_mirror)
    monkeypatch.setattr(arms_mod, "run_instance", fake_run_instance)
    monkeypatch.setattr(harvest_mod, "harvest_instance", lambda *a, **k: None)

    rc = cli.main([
        "run", "--instances", *insts, "--run-id", "t",
        "--workspace-root", str(ws_root),
        "--max-parallel", "3",
    ])

    assert rc == 0
    mirror_events = [e for e in events if e[0] == "mirror"]
    assert mirror_events == [("mirror", "demo/demo", ws_root / "cache" / "repos")]
    assert events[0] == mirror_events[0], "pre-warm must precede every run_instance"
    assert sorted(e[1] for e in events if e[0] == "run") == sorted(insts)


def test_run_verified500_batch_selection(cli_env, fixture_instance, monkeypatch, tmp_path):
    insts = {
        f"repo__repo-{i:03d}": dataclasses.replace(
            fixture_instance,
            instance_id=f"repo__repo-{i:03d}",
            repo="repo/repo",
        )
        for i in range(500)
    }
    monkeypatch.setattr(instances_mod, "load_instances", lambda *a, **k: insts)
    dispatched: list[str] = []

    def fake_run_instance(run_id, inst, ws_root, **kwargs):
        dispatched.append(inst.instance_id)
        return _completed_state()

    monkeypatch.setattr(arms_mod, "run_instance", fake_run_instance)
    monkeypatch.setattr(harvest_mod, "harvest_instance", lambda *a, **k: None)

    rc = cli.main([
        "run",
        "--instance-set", "verified500",
        "--batch", "verified001",
        "--run-id", "t",
        "--workspace-root", str(tmp_path / "wsroot"),
        "--arms", "baseline,fvk",
    ])

    assert rc == 0
    assert dispatched == [f"repo__repo-{i:03d}" for i in range(10)]


# ---------------------------------------------------------------------------
# list
# ---------------------------------------------------------------------------

def test_list_groups_by_repo(monkeypatch, capsys):
    monkeypatch.setattr(
        instances_mod,
        "submodule_instance_ids",
        lambda: ["demo__demo-1", "demo__demo-2", "scikit-learn__scikit-learn-7"],
    )

    rc = cli.main(["list"])

    assert rc == 0
    out = capsys.readouterr().out
    assert "3 instances across 2 repos" in out
    assert "demo__demo (2)" in out
    assert "scikit-learn__scikit-learn (1)" in out
    assert "demo__demo-1" in out


def test_list_annotates_run_statuses(monkeypatch, tmp_path, capsys):
    monkeypatch.setattr(
        instances_mod,
        "submodule_instance_ids",
        lambda: ["demo__demo-1", "demo__demo-2"],
    )
    results_dir = tmp_path / "results"
    monkeypatch.setattr(config, "RESULTS_DIR", results_dir)
    inst_dir = results_dir / "t" / "demo__demo-1"
    inst_dir.mkdir(parents=True)
    (inst_dir / "manifest.json").write_text(json.dumps({
        "arms": {
            "baseline": {"status": "completed", "reason": None},
            "fvk": {"status": "failed", "reason": "timeout"},
            "control": {"status": "skipped", "reason": "baseline_failed"},
        }
    }), encoding="utf-8")

    rc = cli.main(["list", "--run-id", "t"])

    assert rc == 0
    out = capsys.readouterr().out
    line1 = next(l for l in out.splitlines() if "demo__demo-1" in l)
    assert "baseline=completed" in line1
    assert "fvk=failed(timeout)" in line1
    assert "control=skipped(baseline_failed)" in line1
    line2 = next(l for l in out.splitlines() if "demo__demo-2" in l)
    assert "no results" in line2


def test_list_annotates_batches(capsys):
    """The full listing (real submodule ids) tags batch membership."""
    rc = cli.main(["list"])

    assert rc == 0
    out = capsys.readouterr().out
    line = next(l for l in out.splitlines() if "astropy__astropy-13398" in l)
    assert "[batch1]" in line
    line = next(l for l in out.splitlines() if "django__django-10554" in l)
    assert "[batch1]" in line
    for name in batches.BATCHES:
        assert f"[{name}]" in out


def test_list_batch_filter(capsys):
    rc = cli.main(["list", "--batch", "batch4"])

    assert rc == 0
    out = capsys.readouterr().out
    # Instance lines are indented; repo-group headers start at column 0.
    listed = [l.split()[0] for l in out.splitlines() if l.startswith("  ")]
    assert sorted(listed) == sorted(batches.BATCHES["batch4"])
    assert "9 instances" in out


# ---------------------------------------------------------------------------
# evaluate
# ---------------------------------------------------------------------------

def _seed_run(results_dir: Path, rid: str, iid: str = "demo__demo-1") -> Path:
    inst_dir = results_dir / rid / iid
    (inst_dir / "solutions").mkdir(parents=True)
    (inst_dir / "solutions" / "solution_baseline.patch").write_text(
        "diff --git a/lib.py b/lib.py\n+x\n", encoding="utf-8"
    )
    (inst_dir / "manifest.json").write_text(json.dumps({
        "arms": {
            "baseline": {"status": "completed", "reason": None, "session_id": "s",
                         "num_turns": 3, "duration_seconds": 1.0},
            "fvk": {"status": "skipped", "reason": "baseline_failed"},
            "control": {"status": "skipped", "reason": "baseline_failed"},
        }
    }), encoding="utf-8")
    (results_dir / rid / "run_manifest.json").write_text(json.dumps({
        "run_id": rid,
        "created_utc": "2026-06-13T00:00:00+00:00",
        "host": {"hostname": "h"},
        "invocation": {"model": "m"},
    }), encoding="utf-8")
    return inst_dir


def test_evaluate_happy(monkeypatch, tmp_path, capsys):
    results_dir = tmp_path / "results"
    monkeypatch.setattr(config, "RESULTS_DIR", results_dir)
    _seed_run(results_dir, "t")
    calls = []

    def fake_run_official_eval(rid, arm, ids, **kwargs):
        calls.append(("run", arm, tuple(ids), kwargs.get("max_workers")))
        return 0

    def fake_harvest_eval(rid, arm, **kwargs):
        calls.append(("harvest", arm))
        return {"demo__demo-1": {"resolved": True, "found": True,
                                 "ftp_pass": 1, "ftp_total": 1,
                                 "ptp_pass": 1, "ptp_total": 1}}

    monkeypatch.setattr(evaluate_mod, "run_official_eval", fake_run_official_eval)
    monkeypatch.setattr(evaluate_mod, "harvest_eval", fake_harvest_eval)

    rc = cli.main(["evaluate", "--run-id", "t", "--arms", "baseline", "--max-workers", "2"])

    assert rc == 0
    assert calls == [("run", "baseline", ("demo__demo-1",), 2), ("harvest", "baseline")]
    # build_predictions ran for real.
    preds = results_dir / "t" / "eval" / "predictions_baseline.jsonl"
    assert json.loads(preds.read_text(encoding="utf-8"))["instance_id"] == "demo__demo-1"
    # Reports + index were written.
    assert (results_dir / "t" / "scores.json").is_file()
    assert (results_dir / "t" / "scores.md").is_file()
    assert "t" in (results_dir / "INDEX.md").read_text(encoding="utf-8")
    out = capsys.readouterr().out
    assert "scores" in out


def test_evaluate_defaults_to_manifest_arms(monkeypatch, tmp_path):
    results_dir = tmp_path / "results"
    monkeypatch.setattr(config, "RESULTS_DIR", results_dir)
    _seed_run(results_dir, "t")
    run_dir = results_dir / "t"
    manifest = json.loads((run_dir / "run_manifest.json").read_text(encoding="utf-8"))
    manifest["arms"] = ["baseline", "fvk"]
    (run_dir / "run_manifest.json").write_text(json.dumps(manifest), encoding="utf-8")
    (run_dir / "demo__demo-1" / "solutions" / "solution_fvk.patch").write_text(
        "diff --git a/lib.py b/lib.py\n+y\n",
        encoding="utf-8",
    )
    calls = []

    def fake_run_official_eval(rid, arm, ids, **kwargs):
        calls.append(("run", arm, tuple(ids)))
        return 0

    def fake_harvest_eval(rid, arm, **kwargs):
        calls.append(("harvest", arm))
        return {"demo__demo-1": {"resolved": False, "found": True,
                                 "ftp_pass": 0, "ftp_total": 1,
                                 "ptp_pass": 1, "ptp_total": 1}}

    monkeypatch.setattr(evaluate_mod, "run_official_eval", fake_run_official_eval)
    monkeypatch.setattr(evaluate_mod, "harvest_eval", fake_harvest_eval)

    rc = cli.main(["evaluate", "--run-id", "t"])

    assert rc == 0
    assert calls == [
        ("run", "baseline", ("demo__demo-1",)), ("harvest", "baseline"),
        ("run", "fvk", ("demo__demo-1",)), ("harvest", "fvk"),
    ]


def test_evaluate_harness_failure_exits_nonzero(monkeypatch, tmp_path, capsys):
    results_dir = tmp_path / "results"
    monkeypatch.setattr(config, "RESULTS_DIR", results_dir)
    _seed_run(results_dir, "t")
    monkeypatch.setattr(evaluate_mod, "run_official_eval", lambda *a, **k: 3)
    monkeypatch.setattr(evaluate_mod, "harvest_eval", lambda *a, **k: {})

    rc = cli.main(["evaluate", "--run-id", "t", "--arms", "baseline"])

    assert rc == 1
    assert "exit" in capsys.readouterr().out.lower()


def test_evaluate_no_predictions_exits_nonzero(monkeypatch, tmp_path, capsys):
    results_dir = tmp_path / "results"
    monkeypatch.setattr(config, "RESULTS_DIR", results_dir)
    (results_dir / "t").mkdir(parents=True)  # run dir with no solutions at all
    monkeypatch.setattr(
        evaluate_mod, "run_official_eval",
        lambda *a, **k: pytest.fail("harness must not run without predictions"),
    )

    rc = cli.main(["evaluate", "--run-id", "t", "--arms", "baseline"])

    assert rc == 1
    assert "no predictions" in capsys.readouterr().out


def test_evaluate_missing_run_dir(monkeypatch, tmp_path, capsys):
    monkeypatch.setattr(config, "RESULTS_DIR", tmp_path / "results")

    rc = cli.main(["evaluate", "--run-id", "ghost"])

    assert rc == 1
    assert "ghost" in capsys.readouterr().out


# ---------------------------------------------------------------------------
# report
# ---------------------------------------------------------------------------

def test_report_prints_aggregates(monkeypatch, tmp_path, capsys):
    results_dir = tmp_path / "results"
    monkeypatch.setattr(config, "RESULTS_DIR", results_dir)
    _seed_run(results_dir, "t")

    rc = cli.main(["report", "--run-id", "t"])

    assert rc == 0
    assert (results_dir / "t" / "scores.md").is_file()
    assert (results_dir / "INDEX.md").is_file()
    out = capsys.readouterr().out
    assert "scores.md" in out
    assert "## Aggregates" in out


# ---------------------------------------------------------------------------
# validate-gold
# ---------------------------------------------------------------------------

def test_validate_gold_all_resolved(cli_env, fixture_instance, monkeypatch, capsys):
    received = {}

    def fake_gold_eval(rid, ids, **kwargs):
        received["args"] = (rid, list(ids))
        return {iid: True for iid in ids}

    monkeypatch.setattr(evaluate_mod, "gold_eval", fake_gold_eval)

    rc = cli.main(["validate-gold", "--run-id", "g", "--all"])

    assert rc == 0
    assert received["args"] == ("g", [fixture_instance.instance_id])
    assert "resolved" in capsys.readouterr().out


def test_validate_gold_failure(cli_env, fixture_instance, monkeypatch, capsys):
    monkeypatch.setattr(
        evaluate_mod, "gold_eval",
        lambda rid, ids, **kw: {fixture_instance.instance_id: False},
    )

    rc = cli.main([
        "validate-gold", "--run-id", "g",
        "--instances", fixture_instance.instance_id,
    ])

    assert rc == 1


def test_validate_gold_batch(cli_env, fixture_instance, monkeypatch):
    _fake_45_instances(fixture_instance, monkeypatch)
    received: dict = {}

    def fake_gold_eval(rid, ids, **kwargs):
        received["ids"] = list(ids)
        return {iid: True for iid in ids}

    monkeypatch.setattr(evaluate_mod, "gold_eval", fake_gold_eval)

    rc = cli.main(["validate-gold", "--run-id", "g", "--batch", "batch3"])

    assert rc == 0
    assert received["ids"] == list(batches.BATCHES["batch3"])


# ---------------------------------------------------------------------------
# doctor
# ---------------------------------------------------------------------------

def test_doctor_ok_and_fail_exit_codes(monkeypatch, capsys):
    monkeypatch.setattr(
        doctor_mod, "run_checks",
        lambda **kw: [("claude", True, "2.1.169"), ("datasets", None, "missing")],
    )
    assert cli.main(["doctor"]) == 0
    out = capsys.readouterr().out
    assert "OK" in out and "WARN" in out

    monkeypatch.setattr(
        doctor_mod, "run_checks",
        lambda **kw: [("claude", True, "ok"), ("docker", False, "down")],
    )
    assert cli.main(["doctor"]) == 1
    assert "FAIL" in capsys.readouterr().out


def test_doctor_no_eval_checks_passthrough(monkeypatch):
    seen = {}

    def fake_checks(*, eval_checks=True, agent="claude", claude_bin="claude", codex_bin="codex"):
        seen["eval_checks"] = eval_checks
        seen["agent"] = agent
        return [("claude", True, "ok")]

    monkeypatch.setattr(doctor_mod, "run_checks", fake_checks)

    assert cli.main(["doctor", "--no-eval-checks"]) == 0
    assert seen["eval_checks"] is False
    assert seen["agent"] == "claude"


def test_doctor_agent_codex_passthrough(monkeypatch):
    seen = {}

    def fake_checks(*, eval_checks=True, agent="claude", claude_bin="claude", codex_bin="codex"):
        seen["agent"] = agent
        seen["codex_bin"] = codex_bin
        return [("codex", True, "ok"), ("codex_auth", True, "Logged in using ChatGPT")]

    monkeypatch.setattr(doctor_mod, "run_checks", fake_checks)

    assert cli.main(["doctor", "--agent", "codex", "--codex-bin", "/opt/codex"]) == 0
    assert seen == {"agent": "codex", "codex_bin": "/opt/codex"}


def test_doctor_canary_and_probe_model(monkeypatch, capsys):
    monkeypatch.setattr(doctor_mod, "run_checks", lambda **kw: [("claude", True, "ok")])
    canary_models = []

    def fake_canary(*, model=config.CANARY_MODEL, claude_bin="claude"):
        canary_models.append(model)
        return {
            "result_ok": True, "error": None, "session_id": "sid",
            "audit": {"ok": True, "tool_uses": {}, "violations": [],
                      "marker_warnings": [], "unparseable_lines": 0, "lines": 1},
            "clean": True,
        }

    monkeypatch.setattr(doctor_mod, "run_canary", fake_canary)
    assert cli.main(["doctor", "--canary"]) == 0
    assert cli.main(["doctor", "--probe-model"]) == 0
    assert canary_models == [config.CANARY_MODEL, config.MODEL]
    assert "clean" in capsys.readouterr().out

    def dirty_canary(**kwargs):
        return {
            "result_ok": True, "error": None, "session_id": "sid",
            "audit": {"ok": False, "tool_uses": {"Bash": 1}, "violations": ["Bash"],
                      "marker_warnings": [], "unparseable_lines": 0, "lines": 1},
            "clean": False,
        }

    monkeypatch.setattr(doctor_mod, "run_canary", dirty_canary)
    assert cli.main(["doctor", "--canary"]) == 1
    out = capsys.readouterr().out
    assert "DIRTY" in out and "Bash" in out


def test_doctor_codex_canary(monkeypatch, capsys):
    monkeypatch.setattr(
        doctor_mod,
        "run_checks",
        lambda **kw: [("codex", True, "ok"), ("codex_auth", True, "Logged in using ChatGPT")],
    )
    seen = {}

    def fake_codex_canary(*, model=config.CODEX_MODEL, codex_bin="codex"):
        seen["model"] = model
        seen["codex_bin"] = codex_bin
        return {
            "result_ok": True, "error": None, "session_id": "sid",
            "audit": {"ok": True, "tool_uses": {}, "violations": [],
                      "exec_warnings": [], "unparseable_lines": 0, "lines": 1},
            "clean": True,
        }

    monkeypatch.setattr(doctor_mod, "run_codex_canary", fake_codex_canary)

    assert cli.main(["doctor", "--agent", "codex", "--canary", "--codex-bin", "/opt/codex"]) == 0
    assert seen == {"model": config.CODEX_MODEL, "codex_bin": "/opt/codex"}
    assert "canary: clean" in capsys.readouterr().out

    def dirty_codex_canary(**kwargs):
        return {
            "result_ok": True, "error": None, "session_id": "sid",
            "audit": {"ok": False, "tool_uses": {"mcp__x": 1}, "violations": ["mcp__x"],
                      "exec_warnings": [], "unparseable_lines": 0, "lines": 1},
            "clean": False,
        }

    monkeypatch.setattr(doctor_mod, "run_codex_canary", dirty_codex_canary)
    assert cli.main(["doctor", "--agent", "codex", "--canary"]) == 1
    out = capsys.readouterr().out
    assert "DIRTY" in out and "mcp__x" in out


# ---------------------------------------------------------------------------
# vendor-instances
# ---------------------------------------------------------------------------

def test_vendor_instances(monkeypatch, capsys):
    monkeypatch.setattr(instances_mod, "vendor_instances", lambda **kw: 45)

    rc = cli.main(["vendor-instances"])

    assert rc == 0
    out = capsys.readouterr().out
    assert "45" in out and str(config.INSTANCES_JSON) in out


def test_vendor_instances_failure(monkeypatch, capsys):
    def boom(**kwargs):
        raise RuntimeError("no network")

    monkeypatch.setattr(instances_mod, "vendor_instances", boom)

    rc = cli.main(["vendor-instances"])

    assert rc == 1
    assert "no network" in capsys.readouterr().out

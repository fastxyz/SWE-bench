"""Tests for fvk_bench.report — written before implementation (TDD).

A hand-built ``results/<run_id>/`` tree (manifests with mixed arm statuses,
eval reports for two arms, one empty patch) drives golden-ish assertions on
collect_scores, the rendered markdown, and the cross-run index.
"""

import json
from pathlib import Path

import pytest

import fvk_bench.report as report_mod
from fvk_bench import config

RID = "20260613T000000Z-testhost"
IID_A = "demo__demo-1"
IID_B = "demo__demo-2"
IID_C = "demo__demo-3"

#: Eval entry synthesized for a completed arm whose patch is empty: the
#: harness never runs empty predictions, so the arm scores
#: evaluated-and-unresolved with an explicit reason.
EMPTY_PATCH_EVAL = {
    "resolved": False,
    "ftp": "0/0",
    "ptp": "0/0",
    "reason": "empty_patch",
}


def _arm_state(status, reason=None, *, sid="sid", turns=7, dur=12.5):
    return {
        "status": status,
        "reason": reason,
        "session_id": sid,
        "attempts": 1,
        "started_at": "2026-06-13T00:00:00+00:00",
        "ended_at": "2026-06-13T01:00:00+00:00",
        "num_turns": turns,
        "duration_seconds": dur,
        "audit": None,
    }


def _eval_report(iid, *, resolved, ftp, ptp):
    """report.json payload with the real harness shape; ftp/ptp = (ok, bad)."""
    def section(prefix, ok, bad):
        return {
            "success": [f"{prefix}{i}" for i in range(ok)],
            "failure": [f"{prefix}X{i}" for i in range(bad)],
        }

    return {
        iid: {
            "patch_is_None": False,
            "patch_exists": True,
            "patch_successfully_applied": True,
            "resolved": resolved,
            "tests_status": {
                "FAIL_TO_PASS": section("f", *ftp),
                "PASS_TO_PASS": section("p", *ptp),
                "FAIL_TO_FAIL": {"success": [], "failure": []},
                "PASS_TO_FAIL": {"success": [], "failure": []},
            },
        }
    }


@pytest.fixture()
def fake_run(tmp_path) -> Path:
    """results/<RID>/ with three instances:

    - IID_A: baseline+fvk completed, control failed(timeout); eval reports for
      baseline (unresolved) and fvk (resolved) → one baseline→fvk up-flip.
    - IID_B: all completed; fvk patch EMPTY (no eval report → scores
      evaluated-and-unresolved); baseline and control both resolved → one
      baseline→fvk down-flip.
    - IID_C: all completed; baseline resolved; fvk has a patch but NO eval
      report (eval not run yet → stays unevaluated); control patch EMPTY →
      one baseline→control down-flip.
    """
    results_dir = tmp_path / "results"
    run_dir = results_dir / RID

    a = run_dir / IID_A
    (a / "solutions").mkdir(parents=True)
    (a / "eval").mkdir()
    (a / "manifest.json").write_text(json.dumps({
        "run_id": RID,
        "instance_id": IID_A,
        "arms": {
            "baseline": _arm_state("completed"),
            "fvk": _arm_state("completed"),
            "control": _arm_state("failed", "timeout", sid=None, turns=None, dur=14400.0),
        },
    }), encoding="utf-8")
    (a / "solutions" / "solution_baseline.patch").write_text("diff a\n", encoding="utf-8")
    (a / "solutions" / "solution_fvk.patch").write_text("diff b\n", encoding="utf-8")
    # control patch absent (arm failed before extraction)
    (a / "eval" / "baseline.report.json").write_text(
        json.dumps(_eval_report(IID_A, resolved=False, ftp=(1, 1), ptp=(3, 0))),
        encoding="utf-8",
    )
    (a / "eval" / "fvk.report.json").write_text(
        json.dumps(_eval_report(IID_A, resolved=True, ftp=(2, 0), ptp=(3, 0))),
        encoding="utf-8",
    )

    b = run_dir / IID_B
    (b / "solutions").mkdir(parents=True)
    (b / "eval").mkdir()
    (b / "manifest.json").write_text(json.dumps({
        "run_id": RID,
        "instance_id": IID_B,
        "arms": {
            "baseline": _arm_state("completed"),
            "fvk": _arm_state("completed"),
            "control": _arm_state("completed"),
        },
    }), encoding="utf-8")
    (b / "solutions" / "solution_baseline.patch").write_text("diff c\n", encoding="utf-8")
    (b / "solutions" / "solution_fvk.patch").write_text("", encoding="utf-8")  # EMPTY
    (b / "solutions" / "solution_control.patch").write_text("diff d\n", encoding="utf-8")
    (b / "eval" / "baseline.report.json").write_text(
        json.dumps(_eval_report(IID_B, resolved=True, ftp=(1, 0), ptp=(2, 0))),
        encoding="utf-8",
    )
    (b / "eval" / "control.report.json").write_text(
        json.dumps(_eval_report(IID_B, resolved=True, ftp=(1, 0), ptp=(2, 0))),
        encoding="utf-8",
    )

    c = run_dir / IID_C
    (c / "solutions").mkdir(parents=True)
    (c / "eval").mkdir()
    (c / "manifest.json").write_text(json.dumps({
        "run_id": RID,
        "instance_id": IID_C,
        "arms": {
            "baseline": _arm_state("completed"),
            "fvk": _arm_state("completed"),
            "control": _arm_state("completed"),
        },
    }), encoding="utf-8")
    (c / "solutions" / "solution_baseline.patch").write_text("diff e\n", encoding="utf-8")
    (c / "solutions" / "solution_fvk.patch").write_text("diff f\n", encoding="utf-8")
    (c / "solutions" / "solution_control.patch").write_text("", encoding="utf-8")  # EMPTY
    (c / "eval" / "baseline.report.json").write_text(
        json.dumps(_eval_report(IID_C, resolved=True, ftp=(1, 0), ptp=(2, 0))),
        encoding="utf-8",
    )
    # fvk eval report deliberately absent: a completed arm WITH a patch but
    # no report (eval not run yet) must stay out of denominators and flips.

    # The run-level eval dir (predictions, harness logs) is not an instance.
    (run_dir / "eval").mkdir()

    (run_dir / "run_manifest.json").write_text(json.dumps({
        "run_id": RID,
        "created_utc": "2026-06-13T02:00:00+00:00",
        "host": {"hostname": "testhost", "os": "Linux", "arch": "x86_64", "python": "3.10.0"},
        "claude_version": "2.1.169 (Claude Code)",
        "invocation": {"model": config.MODEL},
    }), encoding="utf-8")

    return results_dir


# ---------------------------------------------------------------------------
# 1. collect_scores
# ---------------------------------------------------------------------------

def test_collect_scores(fake_run):
    scores = report_mod.collect_scores(RID, results_dir=fake_run)

    assert scores["run_id"] == RID
    assert sorted(scores["instances"]) == [IID_A, IID_B, IID_C]

    a = scores["instances"][IID_A]
    assert a["baseline"]["status"] == "completed"
    assert a["baseline"]["reason"] is None
    assert a["baseline"]["num_turns"] == 7
    assert a["baseline"]["duration_seconds"] == 12.5
    assert a["baseline"]["empty_patch"] is False
    assert a["baseline"]["eval"] == {"resolved": False, "ftp": "1/2", "ptp": "3/3"}
    assert a["fvk"]["eval"] == {"resolved": True, "ftp": "2/2", "ptp": "3/3"}
    assert a["control"]["status"] == "failed"
    assert a["control"]["reason"] == "timeout"
    assert a["control"]["empty_patch"] is True  # patch absent
    assert a["control"]["eval"] is None  # failed arm: explained by its status

    b = scores["instances"][IID_B]
    assert b["fvk"]["status"] == "completed"
    assert b["fvk"]["empty_patch"] is True  # zero-byte patch
    # A completed arm with an empty patch never reaches the harness, but it
    # IS evaluated: producing nothing scores unresolved, with the reason explicit.
    assert b["fvk"]["eval"] == EMPTY_PATCH_EVAL
    assert b["baseline"]["eval"]["resolved"] is True
    assert b["control"]["eval"]["resolved"] is True

    c = scores["instances"][IID_C]
    assert c["fvk"]["empty_patch"] is False
    assert c["fvk"]["eval"] is None  # patch present but eval not run → unevaluated
    assert c["control"]["empty_patch"] is True
    assert c["control"]["eval"] == EMPTY_PATCH_EVAL  # control empty patch too

    agg = scores["aggregates"]
    assert agg["arms"] == {
        "baseline": {"resolved": 2, "evaluated": 3},
        "fvk": {"resolved": 1, "evaluated": 2},
        "control": {"resolved": 1, "evaluated": 2},
    }
    assert agg["flips"]["baseline_to_fvk"] == {"up": [IID_A], "down": [IID_B]}
    assert agg["flips"]["baseline_to_control"] == {"up": [], "down": [IID_C]}
    assert agg["fvk_vs_control_delta"] == 0


def test_collect_scores_missing_run(tmp_path):
    scores = report_mod.collect_scores("no-such-run", results_dir=tmp_path)

    assert scores["instances"] == {}
    assert scores["aggregates"]["arms"]["baseline"] == {"resolved": 0, "evaluated": 0}


# ---------------------------------------------------------------------------
# 2. render_scores_md
# ---------------------------------------------------------------------------

def test_render_scores_md(fake_run):
    scores = report_mod.collect_scores(RID, results_dir=fake_run)
    run_manifest = json.loads(
        (fake_run / RID / "run_manifest.json").read_text(encoding="utf-8")
    )

    md = report_mod.render_scores_md(scores, run_manifest)

    # Header: run id, model, claude version.
    assert RID in md
    assert config.MODEL in md
    assert "2.1.169" in md

    # Per-instance rows: every arm appears, failed arm shown with its reason.
    row_a = next(line for line in md.splitlines() if line.startswith(f"| {IID_A} "))
    assert "failed(timeout)" in row_a
    assert "✗" in row_a and "✓" in row_a  # baseline unresolved, fvk resolved
    assert "1/2" in row_a and "2/2" in row_a and "3/3" in row_a
    # The failed arm's absent patch is explained by its status — no marker.
    assert "[empty patch]" not in row_a

    row_b = next(line for line in md.splitlines() if line.startswith(f"| {IID_B} "))
    assert "[empty patch]" in row_b  # empty fvk patch flagged explicitly...
    assert "✗" in row_b  # ...and scored unresolved, not left unevaluated
    assert "0/0" in row_b  # synthesized FTP/PTP counts for the empty patch
    assert "—" not in row_b  # every arm of B is evaluated now

    row_c = next(line for line in md.splitlines() if line.startswith(f"| {IID_C} "))
    assert "[empty patch]" in row_c  # control empty patch flagged too...
    assert "✗" in row_c  # ...and scored unresolved
    assert "—" in row_c  # fvk has a patch but no report → still unevaluated

    # Aggregates section.
    assert "## Aggregates" in md
    assert "- baseline resolved: 2/3" in md
    assert "- fvk resolved: 1/2" in md
    assert "- control resolved: 1/2" in md
    assert f"- flips baseline→fvk: +1/-1 (up: {IID_A}; down: {IID_B})" in md
    assert f"- flips baseline→control: +0/-1 (up: none; down: {IID_C})" in md
    assert "- fvk vs control resolved delta: +0" in md


def test_render_scores_md_without_manifest(fake_run):
    scores = report_mod.collect_scores(RID, results_dir=fake_run)

    md = report_mod.render_scores_md(scores, None)

    assert RID in md
    assert "## Aggregates" in md


# ---------------------------------------------------------------------------
# 3. write_reports
# ---------------------------------------------------------------------------

def test_write_reports(fake_run):
    json_path, md_path = report_mod.write_reports(RID, results_dir=fake_run)

    assert json_path == fake_run / RID / "scores.json"
    assert md_path == fake_run / RID / "scores.md"
    on_disk = json.loads(json_path.read_text(encoding="utf-8"))
    assert on_disk == report_mod.collect_scores(RID, results_dir=fake_run)
    assert "## Aggregates" in md_path.read_text(encoding="utf-8")


# ---------------------------------------------------------------------------
# 4. refresh_index
# ---------------------------------------------------------------------------

def test_refresh_index(fake_run):
    # A second run with a manifest but no scores yet → listed with em-dashes.
    bare = fake_run / "20260601T000000Z-otherhost"
    bare.mkdir()
    (bare / "run_manifest.json").write_text(json.dumps({
        "run_id": bare.name,
        "created_utc": "2026-06-01T00:00:00+00:00",
        "host": {"hostname": "otherhost"},
        "invocation": {"model": "claude-test"},
    }), encoding="utf-8")
    (bare / "demo__demo-9").mkdir()
    (bare / "demo__demo-9" / "manifest.json").write_text("{}", encoding="utf-8")
    # A directory without run_manifest.json is not a run → ignored.
    (fake_run / "not-a-run").mkdir()

    report_mod.write_reports(RID, results_dir=fake_run)
    index = report_mod.refresh_index(results_dir=fake_run)

    assert index == fake_run / "INDEX.md"
    text = index.read_text(encoding="utf-8")
    lines = [line for line in text.splitlines() if line.startswith("|")]
    # Sorted run order: the bare run (older id) before RID.
    assert bare.name in lines[2] and RID in lines[3]
    assert "not-a-run" not in text

    scored_row = lines[3]
    assert "testhost" in scored_row
    assert config.MODEL in scored_row
    assert "| 3 |" in scored_row  # three instances
    assert "2/3" in scored_row and "1/2" in scored_row
    assert "2026-06-13T02:00:00+00:00" in scored_row

    bare_row = lines[2]
    assert "otherhost" in bare_row and "claude-test" in bare_row
    assert "| 1 |" in bare_row
    assert "—" in bare_row  # no scores.json yet


def test_refresh_index_empty(tmp_path):
    index = report_mod.refresh_index(results_dir=tmp_path / "results")

    assert index.is_file()
    assert "run_id" in index.read_text(encoding="utf-8")

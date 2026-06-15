"""Tests for fvk_bench.evaluate — written before implementation (TDD).

The official harness is never actually launched: ``subprocess.Popen`` is
monkeypatched to capture the exact argv (golden test of the harness
invocation contract) and report-harvesting runs over a hand-built
``logs/run_evaluation/`` fixture tree whose ``report.json`` shape is copied
from the real harness source (``swebench/harness/grading.py::get_eval_report``).
"""

import json
import sys
from pathlib import Path

import pytest

import fvk_bench.evaluate as evaluate
from fvk_bench import config

RID = "20260613T000000Z-host"


def _report_payload(iid: str, *, resolved: bool, ftp: tuple, ptp: tuple) -> dict:
    """Build a report.json payload with the real harness shape.

    ``ftp``/``ptp`` are (n_success, n_failure) pairs.
    """
    def section(prefix, n_ok, n_bad):
        return {
            "success": [f"{prefix}_ok_{i}" for i in range(n_ok)],
            "failure": [f"{prefix}_bad_{i}" for i in range(n_bad)],
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


class _FakeProc:
    def __init__(self, rc: int = 0):
        self._rc = rc

    def wait(self):
        return self._rc


@pytest.fixture()
def capture_popen(monkeypatch):
    """Replace subprocess.Popen in evaluate with an argv-capturing fake."""
    calls: list[dict] = []

    def fake_popen(argv, cwd=None, stdout=None, stderr=None, **kwargs):
        calls.append({"argv": list(argv), "cwd": cwd})
        return _FakeProc(0)

    monkeypatch.setattr(evaluate.subprocess, "Popen", fake_popen)
    return calls


# ---------------------------------------------------------------------------
# 1. build_predictions: exact jsonl rows, empty patches included, dirs without
#    the arm's patch skipped
# ---------------------------------------------------------------------------

def test_build_predictions_rows(tmp_path):
    run_dir = tmp_path / "results" / RID
    sol_a = run_dir / "sympy__sympy-1" / "solutions"
    sol_a.mkdir(parents=True)
    (sol_a / "solution_baseline.patch").write_text(
        "diff --git a/x.py b/x.py\n+fix\n", encoding="utf-8"
    )
    sol_b = run_dir / "astropy__astropy-2" / "solutions"
    sol_b.mkdir(parents=True)
    (sol_b / "solution_baseline.patch").write_text("", encoding="utf-8")  # empty
    # Instance dir without a baseline patch and a stray run-level file: skipped.
    (run_dir / "django__django-3" / "solutions").mkdir(parents=True)
    (run_dir / "run_manifest.json").write_text("{}", encoding="utf-8")

    path, ids = evaluate.build_predictions(run_dir, "baseline")

    assert path == run_dir / "eval" / "predictions_baseline.jsonl"
    assert ids == ["astropy__astropy-2", "sympy__sympy-1"]  # sorted, empty included
    rows = [json.loads(line) for line in path.read_text(encoding="utf-8").splitlines()]
    assert rows == [
        {
            "instance_id": "astropy__astropy-2",
            "model_name_or_path": f"{RID}__baseline",
            "model_patch": "",
        },
        {
            "instance_id": "sympy__sympy-1",
            "model_name_or_path": f"{RID}__baseline",
            "model_patch": "diff --git a/x.py b/x.py\n+fix\n",
        },
    ]


def test_build_predictions_no_solutions(tmp_path):
    run_dir = tmp_path / "results" / RID
    run_dir.mkdir(parents=True)

    path, ids = evaluate.build_predictions(run_dir, "fvk")

    assert ids == []
    assert path.read_text(encoding="utf-8") == ""


# ---------------------------------------------------------------------------
# 2. run_official_eval: golden argv, cwd=REPO_ROOT, log file created
# ---------------------------------------------------------------------------

def test_run_official_eval_golden_argv(tmp_path, capture_popen):
    results_dir = tmp_path / "results"

    rc = evaluate.run_official_eval(
        RID, "fvk", ["sympy__sympy-1", "astropy__astropy-2"],
        results_dir=results_dir, max_workers=2,
    )

    assert rc == 0
    eval_dir = (results_dir / RID / "eval").resolve()
    assert capture_popen[0]["argv"] == [
        sys.executable, "-m", "swebench.harness.run_evaluation",
        "--dataset_name", config.DATASET_NAME,
        "--predictions_path", str(eval_dir / "predictions_fvk.jsonl"),
        "--run_id", f"{RID}.fvk",
        "--instance_ids", "sympy__sympy-1", "astropy__astropy-2",
        "--max_workers", "2",
        "--namespace", "swebench",
        "--report_dir", str(eval_dir),
    ]
    assert capture_popen[0]["cwd"] == config.REPO_ROOT
    # Harness output is streamed to a per-arm log, not swallowed.
    log = results_dir / RID / "eval" / "harness_fvk.log"
    assert log.is_file()
    assert "swebench.harness.run_evaluation" in log.read_text(encoding="utf-8")


def test_run_official_eval_namespace_none_and_timeout(tmp_path, capture_popen):
    rc = evaluate.run_official_eval(
        RID, "baseline", ["i1"],
        results_dir=tmp_path / "results", namespace=None, timeout=900,
    )

    assert rc == 0
    argv = capture_popen[0]["argv"]
    assert argv[argv.index("--namespace") + 1] == "none"
    assert argv[argv.index("--timeout") + 1] == "900"
    assert argv[argv.index("--max_workers") + 1] == "4"  # default


def test_run_official_eval_nonzero_exit_not_raised(tmp_path, monkeypatch):
    def fake_popen(argv, cwd=None, stdout=None, stderr=None, **kwargs):
        return _FakeProc(3)

    monkeypatch.setattr(evaluate.subprocess, "Popen", fake_popen)

    rc = evaluate.run_official_eval(RID, "fvk", ["i1"], results_dir=tmp_path / "r")

    assert rc == 3


def test_run_official_eval_retries_missing_nonempty_reports_locally(
    tmp_path, monkeypatch
):
    results_dir = tmp_path / "results"
    repo_root = tmp_path / "repo_root"
    monkeypatch.setattr(evaluate.config, "REPO_ROOT", repo_root)
    calls: list[dict] = []

    def fake_popen(argv, cwd=None, stdout=None, stderr=None, **kwargs):
        calls.append({"argv": list(argv), "cwd": cwd})
        if argv[argv.index("--namespace") + 1] == "none":
            retried = (
                repo_root
                / "logs"
                / "run_evaluation"
                / f"{RID}.baseline"
                / f"{RID}__baseline"
                / "demo__demo-2"
            )
            retried.mkdir(parents=True)
            (retried / "report.json").write_text(
                json.dumps(
                    _report_payload("demo__demo-2", resolved=True, ftp=(1, 0), ptp=(1, 0))
                ),
                encoding="utf-8",
            )
            return _FakeProc(0)
        return _FakeProc(7)

    monkeypatch.setattr(evaluate.subprocess, "Popen", fake_popen)
    eval_dir = results_dir / RID / "eval"
    eval_dir.mkdir(parents=True)
    (eval_dir / "predictions_baseline.jsonl").write_text(
        "\n".join(
            [
                json.dumps(
                    {
                        "instance_id": "demo__demo-1",
                        "model_name_or_path": f"{RID}__baseline",
                        "model_patch": "diff --git a/a b/a\n+fix\n",
                    }
                ),
                json.dumps(
                    {
                        "instance_id": "demo__demo-2",
                        "model_name_or_path": f"{RID}__baseline",
                        "model_patch": "diff --git a/b b/b\n+fix\n",
                    }
                ),
                json.dumps(
                    {
                        "instance_id": "demo__demo-3",
                        "model_name_or_path": f"{RID}__baseline",
                        "model_patch": "",
                    }
                ),
            ]
        )
        + "\n",
        encoding="utf-8",
    )
    completed = (
        repo_root
        / "logs"
        / "run_evaluation"
        / f"{RID}.baseline"
        / f"{RID}__baseline"
        / "demo__demo-1"
    )
    completed.mkdir(parents=True)
    (completed / "report.json").write_text(
        json.dumps(_report_payload("demo__demo-1", resolved=True, ftp=(1, 0), ptp=(1, 0))),
        encoding="utf-8",
    )

    rc = evaluate.run_official_eval(
        RID,
        "baseline",
        ["demo__demo-1", "demo__demo-2", "demo__demo-3"],
        results_dir=results_dir,
    )

    assert rc == 0
    assert len(calls) == 2
    first_argv = calls[0]["argv"]
    retry_argv = calls[1]["argv"]
    assert first_argv[first_argv.index("--namespace") + 1] == "swebench"
    assert retry_argv[retry_argv.index("--namespace") + 1] == "none"
    assert retry_argv[retry_argv.index("--instance_ids") + 1:] == [
        "demo__demo-2",
        "--max_workers",
        "4",
        "--namespace",
        "none",
        "--report_dir",
        str(eval_dir.resolve()),
    ]


# ---------------------------------------------------------------------------
# 3. harvest_eval: copies report.json per instance, parses tests_status counts,
#    tolerates missing reports
# ---------------------------------------------------------------------------

def test_harvest_eval(tmp_path):
    results_dir = tmp_path / "results"
    repo_root = tmp_path / "repo_root"
    run_dir = results_dir / RID
    for iid in ("demo__demo-1", "demo__demo-2", "demo__demo-3"):
        (run_dir / iid).mkdir(parents=True)
    (run_dir / "eval").mkdir()  # the run-level eval dir is NOT an instance

    model_dir = repo_root / "logs" / "run_evaluation" / f"{RID}.baseline" / f"{RID}__baseline"
    r1 = _report_payload("demo__demo-1", resolved=True, ftp=(2, 0), ptp=(3, 0))
    r2 = _report_payload("demo__demo-2", resolved=False, ftp=(1, 1), ptp=(1, 1))
    for iid, payload in [("demo__demo-1", r1), ("demo__demo-2", r2)]:
        d = model_dir / iid
        d.mkdir(parents=True)
        (d / "report.json").write_text(json.dumps(payload), encoding="utf-8")
    # demo-3 has no report.json (e.g. empty patch never ran).

    summary = evaluate.harvest_eval(
        RID, "baseline", results_dir=results_dir, repo_root=repo_root
    )

    assert summary == {
        "demo__demo-1": {
            "resolved": True, "found": True,
            "ftp_pass": 2, "ftp_total": 2, "ptp_pass": 3, "ptp_total": 3,
        },
        "demo__demo-2": {
            "resolved": False, "found": True,
            "ftp_pass": 1, "ftp_total": 2, "ptp_pass": 1, "ptp_total": 2,
        },
        "demo__demo-3": {
            "resolved": None, "found": False,
            "ftp_pass": 0, "ftp_total": 0, "ptp_pass": 0, "ptp_total": 0,
        },
    }
    # Reports were copied into the per-instance results tree.
    copied = run_dir / "demo__demo-1" / "eval" / "baseline.report.json"
    assert json.loads(copied.read_text(encoding="utf-8")) == r1
    assert (run_dir / "demo__demo-2" / "eval" / "baseline.report.json").is_file()
    assert not (run_dir / "demo__demo-3" / "eval").exists()


def test_harvest_eval_normalizes_astropy_7606_empty_param_alias(tmp_path):
    results_dir = tmp_path / "results"
    repo_root = tmp_path / "repo_root"
    run_dir = results_dir / RID
    iid = "astropy__astropy-7606"
    (run_dir / iid).mkdir(parents=True)

    model_dir = repo_root / "logs" / "run_evaluation" / f"{RID}.baseline" / f"{RID}__baseline" / iid
    model_dir.mkdir(parents=True)
    payload = _report_payload(iid, resolved=False, ftp=(1, 0), ptp=(241, 1))
    entry = payload[iid]
    ptp = entry["tests_status"]["PASS_TO_PASS"]
    ptp["failure"] = ["astropy/units/tests/test_units.py::test_compose_roundtrip[]"]
    (model_dir / "report.json").write_text(json.dumps(payload), encoding="utf-8")
    (model_dir / "test_output.txt").write_text(
        "astropy/units/tests/test_units.py::test_compose_roundtrip[unit0] PASSED\n"
        "==================== 242 passed, 1 warnings in 1.28 seconds ====================\n",
        encoding="utf-8",
    )

    summary = evaluate.harvest_eval(
        RID, "baseline", results_dir=results_dir, repo_root=repo_root
    )

    assert summary[iid]["resolved"] is True
    assert summary[iid]["ptp_pass"] == 242
    assert summary[iid]["ptp_total"] == 242
    copied = json.loads(
        (run_dir / iid / "eval" / "baseline.report.json").read_text(encoding="utf-8")
    )
    copied_entry = copied[iid]
    assert copied_entry["resolved"] is True
    assert copied_entry["fvk_bench_normalizations"]


# ---------------------------------------------------------------------------
# 4. gold_eval: predictions_path literal "gold", dotted goldcheck run id,
#    resolved map with None for missing reports
# ---------------------------------------------------------------------------

def test_gold_eval(tmp_path, capture_popen):
    results_dir = tmp_path / "results"
    repo_root = tmp_path / "repo_root"
    gold_dir = repo_root / "logs" / "run_evaluation" / f"{RID}.goldcheck" / "gold"
    d1 = gold_dir / "demo__demo-1"
    d1.mkdir(parents=True)
    (d1 / "report.json").write_text(
        json.dumps(_report_payload("demo__demo-1", resolved=True, ftp=(1, 0), ptp=(1, 0))),
        encoding="utf-8",
    )

    res = evaluate.gold_eval(
        RID, ["demo__demo-1", "demo__demo-2"],
        max_workers=3, results_dir=results_dir, repo_root=repo_root,
    )

    assert res == {"demo__demo-1": True, "demo__demo-2": None}
    argv = capture_popen[0]["argv"]
    assert argv[argv.index("--predictions_path") + 1] == "gold"
    assert argv[argv.index("--run_id") + 1] == f"{RID}.goldcheck"
    assert argv[argv.index("--max_workers") + 1] == "3"
    assert argv[argv.index("--instance_ids") + 1] == "demo__demo-1"
    assert (results_dir / RID / "eval" / "harness_goldcheck.log").is_file()


def test_gold_eval_retries_missing_reports_with_local_images(
    tmp_path, monkeypatch
):
    results_dir = tmp_path / "results"
    repo_root = tmp_path / "repo_root"
    monkeypatch.setattr(evaluate.config, "REPO_ROOT", repo_root)
    calls: list[dict] = []

    def fake_popen(argv, cwd=None, stdout=None, stderr=None, **kwargs):
        calls.append({"argv": list(argv), "cwd": cwd})
        if argv[argv.index("--namespace") + 1] == "none":
            retried = (
                repo_root
                / "logs"
                / "run_evaluation"
                / f"{RID}.goldcheck"
                / "gold"
                / "demo__demo-2"
            )
            retried.mkdir(parents=True)
            (retried / "report.json").write_text(
                json.dumps(
                    _report_payload("demo__demo-2", resolved=True, ftp=(1, 0), ptp=(1, 0))
                ),
                encoding="utf-8",
            )
        return _FakeProc(0)

    monkeypatch.setattr(evaluate.subprocess, "Popen", fake_popen)
    gold_dir = repo_root / "logs" / "run_evaluation" / f"{RID}.goldcheck" / "gold"
    d1 = gold_dir / "demo__demo-1"
    d1.mkdir(parents=True)
    (d1 / "report.json").write_text(
        json.dumps(_report_payload("demo__demo-1", resolved=True, ftp=(1, 0), ptp=(1, 0))),
        encoding="utf-8",
    )

    res = evaluate.gold_eval(
        RID,
        ["demo__demo-1", "demo__demo-2"],
        max_workers=2,
        results_dir=results_dir,
        repo_root=repo_root,
    )

    assert res == {"demo__demo-1": True, "demo__demo-2": True}
    assert len(calls) == 2
    retry_argv = calls[1]["argv"]
    assert retry_argv[retry_argv.index("--namespace") + 1] == "none"
    assert retry_argv[retry_argv.index("--instance_ids") + 1:] == [
        "demo__demo-2",
        "--max_workers",
        "2",
        "--namespace",
        "none",
    ]

"""Official SWE-bench evaluation pipeline (predictions → harness → harvest).

This module is a thin, auditable shim over ``swebench.harness.run_evaluation``
(the officially recommended dockerized scorer, vendored in this repo):

- :func:`build_predictions` turns harvested solution patches into the
  predictions JSONL the harness consumes. Empty patches are deliberately
  included — they score unresolved (the harness skips running them but its
  aggregate report counts them as ``empty_patch``).
- :func:`run_official_eval` launches the harness once per arm with a dotted
  run id ``<run_id>.<arm>``, streaming all harness output to
  ``results/<run_id>/eval/harness_<arm>.log``. The exit code is returned,
  never raised — a partially failed eval still leaves harvestable reports.
- :func:`harvest_eval` copies each per-instance ``report.json`` (written by
  the harness under ``<repo_root>/logs/run_evaluation/...``) into the
  results tree and reduces it to resolved/FTP/PTP counts.
- :func:`gold_eval` validates the eval environment by scoring the official
  gold patches (``--predictions_path gold``); a machine where gold does not
  resolve produces uninterpretable real scores.

Harness facts this module relies on (verified against the vendored source):
per-instance reports land at
``logs/run_evaluation/<run_id>/<model_name_or_path>/<instance_id>/report.json``
relative to the harness CWD; the gold model name is ``"gold"``; the
``--report_dir`` flag exists but the aggregate JSON is written to the CWD as
``<model>.<run_id>.json`` regardless (see ``make_run_report``), so it is
relocated into the run's ``eval/`` directory afterwards.
"""

import json
import shutil
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path

from fvk_bench import config

#: Summary recorded for an instance whose report.json was never produced
#: (eval failed, image missing, or the patch was empty and never ran).
_MISSING_SUMMARY = {
    "resolved": None,
    "found": False,
    "ftp_pass": 0,
    "ftp_total": 0,
    "ptp_pass": 0,
    "ptp_total": 0,
}

_PYTEST_ID_ALIASES: tuple[dict[str, str], ...] = (
    {
        "instance_id": "astropy__astropy-7606",
        "section": "PASS_TO_PASS",
        "expected": "astropy/units/tests/test_units.py::test_compose_roundtrip[]",
        "emitted": "astropy/units/tests/test_units.py::test_compose_roundtrip[unit0]",
    },
)


def build_predictions(run_dir: Path, arm: str) -> tuple[Path, list[str]]:
    """Write the predictions JSONL for ``arm`` from a harvested run directory.

    Scans ``run_dir/*/solutions/solution_<arm>.patch`` (each patch's
    grandparent directory name is the instance id) and writes one JSON row
    per instance to ``run_dir/eval/predictions_<arm>.jsonl``::

        {"instance_id": ..., "model_name_or_path": "<run_dir.name>__<arm>",
         "model_patch": <patch text>}

    Empty patches still emit a row (empty string) — they score unresolved.

    Returns ``(predictions_path, sorted instance ids)``.
    """
    run_dir = Path(run_dir)
    model_name = f"{run_dir.name}__{arm}"
    rows: list[dict] = []
    ids: list[str] = []
    for patch_path in sorted(run_dir.glob(f"*/solutions/solution_{arm}.patch")):
        iid = patch_path.parent.parent.name
        rows.append(
            {
                "instance_id": iid,
                "model_name_or_path": model_name,
                # git binary diffs are base85 text, so utf-8 always decodes;
                # errors="replace" keeps a pathological patch from crashing
                # prediction building (it would just score unresolved).
                "model_patch": patch_path.read_bytes().decode("utf-8", errors="replace"),
            }
        )
        ids.append(iid)
    out = run_dir / "eval" / f"predictions_{arm}.jsonl"
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(
        "".join(json.dumps(row) + "\n" for row in rows), encoding="utf-8"
    )
    return out, ids


def _launch_harness(argv: list[str], log_path: Path, repo_root: Path) -> int:
    """Run one harness invocation, streaming stdout+stderr to ``log_path``.

    The log is appended (re-runs preserve history) and each invocation is
    prefixed with a timestamped header recording the exact argv. Returns the
    process exit code; a spawn failure returns 127 and is recorded in the log.
    """
    log_path.parent.mkdir(parents=True, exist_ok=True)
    with open(log_path, "a", encoding="utf-8") as log:
        stamp = datetime.now(timezone.utc).isoformat()
        log.write(f"=== {stamp} :: {' '.join(argv)}\n")
        log.flush()
        try:
            proc = subprocess.Popen(
                argv, cwd=repo_root, stdout=log, stderr=subprocess.STDOUT
            )
        except OSError as exc:
            log.write(f"spawn failure: {exc}\n")
            return 127
        return proc.wait()


def _relocate_aggregate(
    model_name: str, harness_run_id: str, eval_dir: Path, repo_root: Path
) -> None:
    """Move the harness's aggregate JSON from its CWD into ``eval_dir``.

    The vendored harness ignores ``--report_dir`` for this file and writes
    ``<model>.<run_id>.json`` to its CWD (``make_run_report``); relocating it
    keeps the repo root clean and the artifact next to the rest of the eval.
    """
    stray = Path(repo_root) / f"{model_name}.{harness_run_id}.json"
    if stray.is_file():
        shutil.move(str(stray), str(eval_dir / stray.name))


def _relocate_fallback_aggregate(
    model_name: str, harness_run_id: str, eval_dir: Path, repo_root: Path
) -> None:
    """Keep a retry aggregate without overwriting the primary aggregate."""
    stray = Path(repo_root) / f"{model_name}.{harness_run_id}.json"
    if stray.is_file():
        shutil.move(
            str(stray),
            str(eval_dir / f"{model_name}.{harness_run_id}.local-fallback.json"),
        )


def _nonempty_prediction_ids(predictions_path: Path, instance_ids: list[str]) -> set[str]:
    """Return ids whose prediction patch should produce a harness report."""
    expected = set(instance_ids)
    try:
        lines = Path(predictions_path).read_text(encoding="utf-8").splitlines()
    except OSError:
        return expected
    nonempty: set[str] = set()
    for line in lines:
        if not line.strip():
            continue
        try:
            row = json.loads(line)
        except ValueError:
            return expected
        iid = row.get("instance_id")
        if iid in expected and row.get("model_patch") not in ("", None):
            nonempty.add(iid)
    return nonempty


def _missing_report_ids(
    repo_root: Path,
    harness_run_id: str,
    model_name: str,
    instance_ids: list[str],
    *,
    expected_ids: set[str] | None = None,
) -> list[str]:
    """Return expected instance ids that lack per-instance harness reports."""
    model_dir = Path(repo_root) / "logs" / "run_evaluation" / harness_run_id / model_name
    expected_ids = expected_ids if expected_ids is not None else set(instance_ids)
    return [
        iid
        for iid in instance_ids
        if iid in expected_ids and not (model_dir / iid / "report.json").is_file()
    ]


def _test_output_contains_pass(report_path: Path, test_id: str) -> bool:
    """Return True when the adjacent harness test output shows ``test_id`` passed."""
    test_output = Path(report_path).with_name("test_output.txt")
    try:
        text = test_output.read_text(encoding="utf-8", errors="replace")
    except OSError:
        return False
    return f"{test_id} PASSED" in text


def normalize_report(data: dict, instance_id: str, report_path: Path | None = None) -> bool:
    """Apply narrow compatibility normalizations to a harness ``report.json``.

    Returns True when ``data`` was modified. The raw harness logs remain the
    artifact of record; harvested reports carry these corrections so scoring is
    not distorted by known test-id spelling drift.
    """
    entry = data.get(instance_id)
    if not isinstance(entry, dict):
        return False
    tests_status = entry.get("tests_status") or {}
    notes: list[dict[str, str]] = []

    for alias in _PYTEST_ID_ALIASES:
        if alias["instance_id"] != instance_id:
            continue
        section = tests_status.get(alias["section"]) or {}
        failures = section.get("failure") or []
        if alias["expected"] not in failures:
            continue
        if report_path is None or not _test_output_contains_pass(
            Path(report_path), alias["emitted"]
        ):
            continue

        failures.remove(alias["expected"])
        section["failure"] = failures
        successes = section.setdefault("success", [])
        if alias["expected"] not in successes:
            successes.append(alias["expected"])
        notes.append(
            {
                "reason": "pytest_param_id_alias",
                "section": alias["section"],
                "expected": alias["expected"],
                "emitted": alias["emitted"],
            }
        )

    if not notes:
        return False

    existing = entry.setdefault("fvk_bench_normalizations", [])
    existing.extend(notes)
    ftp_failures = (tests_status.get("FAIL_TO_PASS") or {}).get("failure") or []
    ptp_failures = (tests_status.get("PASS_TO_PASS") or {}).get("failure") or []
    entry["resolved"] = not ftp_failures and not ptp_failures
    return True


def run_official_eval(
    run_id: str,
    arm: str,
    instance_ids: list[str],
    *,
    results_dir: Path = config.RESULTS_DIR,
    max_workers: int = 4,
    namespace: str | None = "swebench",
    timeout: int | None = None,
) -> int:
    """Run the official harness for one arm's predictions.

    The harness runs with cwd ``config.REPO_ROOT`` (it writes its ``logs/``
    tree and aggregate JSON relative to its CWD) and its combined output is
    streamed to ``results/<run_id>/eval/harness_<arm>.log``. ``namespace``
    ``"swebench"`` (the harness default) pulls prebuilt instance images;
    ``None`` maps to the harness's literal ``"none"`` (local builds).

    Returns the harness exit code — nonzero is reported, never raised.
    """
    eval_dir = (Path(results_dir) / run_id / "eval").resolve()
    eval_dir.mkdir(parents=True, exist_ok=True)
    harness_run_id = f"{run_id}.{arm}"
    predictions_path = eval_dir / f"predictions_{arm}.jsonl"
    argv = [
        sys.executable, "-m", "swebench.harness.run_evaluation",
        "--dataset_name", config.DATASET_NAME,
        "--predictions_path", str(predictions_path),
        "--run_id", harness_run_id,
        "--instance_ids", *instance_ids,
        "--max_workers", str(max_workers),
        "--namespace", namespace or "none",
        "--report_dir", str(eval_dir),
    ]
    if timeout is not None:
        argv += ["--timeout", str(timeout)]
    rc = _launch_harness(argv, eval_dir / f"harness_{arm}.log", config.REPO_ROOT)
    _relocate_aggregate(f"{run_id}__{arm}", harness_run_id, eval_dir, config.REPO_ROOT)

    if namespace is not None and predictions_path.is_file():
        expected_ids = _nonempty_prediction_ids(predictions_path, instance_ids)
        missing = _missing_report_ids(
            config.REPO_ROOT,
            harness_run_id,
            f"{run_id}__{arm}",
            instance_ids,
            expected_ids=expected_ids,
        )
        if missing:
            retry_argv = [
                sys.executable, "-m", "swebench.harness.run_evaluation",
                "--dataset_name", config.DATASET_NAME,
                "--predictions_path", str(predictions_path),
                "--run_id", harness_run_id,
                "--instance_ids", *missing,
                "--max_workers", str(max_workers),
                "--namespace", "none",
                "--report_dir", str(eval_dir),
            ]
            if timeout is not None:
                retry_argv += ["--timeout", str(timeout)]
            retry_rc = _launch_harness(
                retry_argv, eval_dir / f"harness_{arm}.log", config.REPO_ROOT
            )
            _relocate_fallback_aggregate(
                f"{run_id}__{arm}", harness_run_id, eval_dir, config.REPO_ROOT
            )
            still_missing = _missing_report_ids(
                config.REPO_ROOT,
                harness_run_id,
                f"{run_id}__{arm}",
                instance_ids,
                expected_ids=expected_ids,
            )
            if retry_rc != 0:
                return retry_rc
            if still_missing:
                return 2
            return 0
    return rc


def summarize_report(data: dict, instance_id: str) -> dict:
    """Reduce one parsed ``report.json`` payload to a flat summary dict.

    The payload shape (from ``swebench.harness.grading.get_eval_report``) is::

        {<iid>: {"resolved": bool, "tests_status": {
            "FAIL_TO_PASS": {"success": [...], "failure": [...]},
            "PASS_TO_PASS": {"success": [...], "failure": [...]}, ...}}}

    ``tests_status`` is absent when the patch never applied — counts are then
    0/0 but ``resolved`` (False) is still meaningful. A payload missing the
    instance entry entirely yields ``resolved=None``.
    """
    entry = data.get(instance_id)
    if not isinstance(entry, dict):
        return dict(_MISSING_SUMMARY, found=True)
    tests_status = entry.get("tests_status") or {}

    def counts(section: str) -> tuple[int, int]:
        sec = tests_status.get(section) or {}
        ok = len(sec.get("success") or [])
        bad = len(sec.get("failure") or [])
        return ok, ok + bad

    ftp_pass, ftp_total = counts("FAIL_TO_PASS")
    ptp_pass, ptp_total = counts("PASS_TO_PASS")
    return {
        "resolved": bool(entry.get("resolved", False)),
        "found": True,
        "ftp_pass": ftp_pass,
        "ftp_total": ftp_total,
        "ptp_pass": ptp_pass,
        "ptp_total": ptp_total,
    }


def harvest_eval(
    run_id: str,
    arm: str,
    *,
    results_dir: Path = config.RESULTS_DIR,
    repo_root: Path = config.REPO_ROOT,
) -> dict:
    """Harvest per-instance harness reports for ``arm`` into the results tree.

    For every instance directory under ``results/<run_id>/`` (the run-level
    ``eval/`` directory excluded), looks for
    ``<repo_root>/logs/run_evaluation/<run_id>.<arm>/<run_id>__<arm>/<iid>/report.json``,
    copies it to ``results/<run_id>/<iid>/eval/<arm>.report.json``, and
    returns ``{iid: summary}`` (see :func:`summarize_report`). Missing
    reports are tolerated: ``found=False, resolved=None``.
    """
    results_dir = Path(results_dir)
    run_dir = results_dir / run_id
    model_dir = (
        Path(repo_root) / "logs" / "run_evaluation"
        / f"{run_id}.{arm}" / f"{run_id}__{arm}"
    )
    summary: dict = {}
    if not run_dir.is_dir():
        return summary
    for inst_dir in sorted(
        p for p in run_dir.iterdir() if p.is_dir() and p.name != "eval"
    ):
        iid = inst_dir.name
        src = model_dir / iid / "report.json"
        if not src.is_file():
            summary[iid] = dict(_MISSING_SUMMARY)
            continue
        try:
            data = json.loads(src.read_text(encoding="utf-8"))
        except ValueError:
            # Malformed report: kept for forensics, scored as unusable.
            dst = inst_dir / "eval" / f"{arm}.report.json"
            dst.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(src, dst)
            summary[iid] = dict(_MISSING_SUMMARY, found=True)
            continue
        dst = inst_dir / "eval" / f"{arm}.report.json"
        dst.parent.mkdir(parents=True, exist_ok=True)
        if normalize_report(data, iid, src):
            dst.write_text(json.dumps(data, indent=2) + "\n", encoding="utf-8")
        else:
            shutil.copy2(src, dst)
        summary[iid] = summarize_report(data, iid)
    return summary


def _update_gold_aggregate(
    aggregate_path: Path, resolved_results: dict[str, bool | None]
) -> None:
    """Keep the relocated gold aggregate consistent with normalized reports."""
    if not Path(aggregate_path).is_file():
        return
    try:
        data = json.loads(Path(aggregate_path).read_text(encoding="utf-8"))
    except (OSError, ValueError):
        return
    changed = False
    resolved_ids = list(data.get("resolved_ids") or [])
    unresolved_ids = list(data.get("unresolved_ids") or [])
    for iid, resolved in resolved_results.items():
        if resolved is not True or iid not in unresolved_ids:
            continue
        unresolved_ids.remove(iid)
        if iid not in resolved_ids:
            resolved_ids.append(iid)
        changed = True
    if not changed:
        return
    data["resolved_ids"] = sorted(resolved_ids)
    data["unresolved_ids"] = sorted(unresolved_ids)
    data["resolved_instances"] = len(resolved_ids)
    data["unresolved_instances"] = len(unresolved_ids)
    notes = data.setdefault("fvk_bench_normalizations", [])
    notes.append(
        {
            "reason": "report_level_pytest_param_id_alias",
            "instances": sorted(iid for iid, resolved in resolved_results.items() if resolved is True),
        }
    )
    Path(aggregate_path).write_text(json.dumps(data, indent=2) + "\n", encoding="utf-8")


def gold_eval(
    run_id: str,
    instance_ids: list[str],
    *,
    max_workers: int = 4,
    results_dir: Path = config.RESULTS_DIR,
    repo_root: Path = config.REPO_ROOT,
) -> dict:
    """Score the official gold patches for ``instance_ids`` (env validation).

    Runs the harness with the literal ``--predictions_path gold`` under run id
    ``<run_id>.goldcheck`` (output streamed to
    ``results/<run_id>/eval/harness_goldcheck.log``), then reads each
    instance's ``report.json`` from the harness logs tree (the gold model
    directory is named ``gold``; a glob across model dirs guards against
    drift). Returns ``{iid: resolved bool | None}`` — ``None`` when no report
    was produced. Gold must resolve everything; anything less means the eval
    environment on this machine is broken.
    """
    repo_root = Path(repo_root)
    eval_dir = (Path(results_dir) / run_id / "eval").resolve()
    eval_dir.mkdir(parents=True, exist_ok=True)
    harness_run_id = f"{run_id}.goldcheck"

    def run_gold(namespace: str, ids: list[str]) -> None:
        argv = [
            sys.executable, "-m", "swebench.harness.run_evaluation",
            "--dataset_name", config.DATASET_NAME,
            "--predictions_path", "gold",
            "--run_id", harness_run_id,
            "--instance_ids", *ids,
            "--max_workers", str(max_workers),
            "--namespace", namespace,
        ]
        _launch_harness(argv, eval_dir / "harness_goldcheck.log", repo_root)

    run_gold("swebench", instance_ids)
    _relocate_aggregate("gold", harness_run_id, eval_dir, repo_root)

    log_root = repo_root / "logs" / "run_evaluation" / harness_run_id
    missing = _missing_report_ids(repo_root, harness_run_id, "gold", instance_ids)
    if missing:
        run_gold("none", missing)
        _relocate_fallback_aggregate("gold", harness_run_id, eval_dir, repo_root)

    results: dict = {}
    for iid in instance_ids:
        report_path = next(iter(sorted(log_root.glob(f"*/{iid}/report.json"))), None)
        resolved: bool | None = None
        if report_path is not None:
            try:
                data = json.loads(report_path.read_text(encoding="utf-8"))
                if normalize_report(data, iid, report_path):
                    report_path.with_name("report.fvk_bench_normalized.json").write_text(
                        json.dumps(data, indent=2) + "\n", encoding="utf-8"
                    )
                entry = data.get(iid)
                if isinstance(entry, dict):
                    resolved = bool(entry.get("resolved", False))
            except ValueError:
                resolved = None
        results[iid] = resolved
    _update_gold_aggregate(eval_dir / f"gold.{harness_run_id}.json", results)
    return results

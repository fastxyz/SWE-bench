"""Command-line interface for the fvk 3-arm benchmark.

This is the ONLY fvk_bench module that prints. Every subcommand returns an
exit code: 0 = full success, 1 = failure, 2 = partial success (some but not
all of the requested work completed).

The happy path for one problem is exactly::

    python -m fvk_bench doctor --canary
    python -m fvk_bench validate-gold --run-id X --instances ID
    python -m fvk_bench run --run-id X --instances ID
    python -m fvk_bench evaluate --run-id X
    python -m fvk_bench report --run-id X

Reusing a run id resumes it (completed arms are skipped by the arm state
machine), so a single problem or all 45 can be processed incrementally.
"""

import argparse
import json
import socket
import time
from pathlib import Path

from fvk_bench import arms, config, doctor, evaluate, harvest, instances, report


def _default_run_id() -> str:
    """UTC timestamp + hostname, e.g. ``20260613T120000Z-benchbox``."""
    return time.strftime("%Y%m%dT%H%M%SZ", time.gmtime()) + "-" + socket.gethostname()


def _parse_arms(spec: str) -> tuple[str, ...] | None:
    """Parse a comma-separated arm list; prints the error and returns None on bad input."""
    requested = tuple(a.strip() for a in spec.split(",") if a.strip())
    unknown = [a for a in requested if a not in config.ARMS]
    if unknown or not requested:
        print(
            f"error: unknown arms: {', '.join(unknown) or spec!r} "
            f"(choose from {', '.join(config.ARMS)})"
        )
        return None
    return requested


def _resolve_ids(args, known: dict) -> list[str] | None:
    """Resolve --instances/--all against the loaded instance set."""
    if args.all:
        return sorted(known)
    unknown = [iid for iid in args.instances if iid not in known]
    if unknown:
        print("error: unknown instance ids: " + ", ".join(unknown))
        print("hint: `python -m fvk_bench list` shows the 45 benchmark instances")
        return None
    return list(dict.fromkeys(args.instances))  # de-dup, keep order


def _load_instances_or_explain() -> dict | None:
    try:
        return instances.load_instances()
    except (RuntimeError, OSError) as exc:
        print(f"error: cannot load instance metadata: {exc}")
        print("hint: run `python -m fvk_bench vendor-instances` first")
        return None


def _arm_label(arm_state: dict) -> str:
    label = arm_state.get("status") or "—"
    if arm_state.get("reason"):
        label += f"({arm_state['reason']})"
    return label


# ---------------------------------------------------------------------------
# list
# ---------------------------------------------------------------------------

def _cmd_list(args) -> int:
    try:
        ids = instances.submodule_instance_ids()
    except RuntimeError as exc:
        print(f"error: {exc}")
        return 1

    groups: dict[str, list[str]] = {}
    for iid in ids:
        groups.setdefault(iid.rsplit("-", 1)[0], []).append(iid)
    print(f"{len(ids)} instances across {len(groups)} repos")

    annotations: dict[str, str] = {}
    if args.run_id:
        run_dir = config.RESULTS_DIR / args.run_id
        for iid in ids:
            manifest_path = run_dir / iid / "manifest.json"
            if not manifest_path.is_file():
                annotations[iid] = "(no results)"
                continue
            try:
                manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
            except (ValueError, OSError):
                annotations[iid] = "(unreadable manifest)"
                continue
            arms_state = manifest.get("arms") or {}
            annotations[iid] = " ".join(
                f"{arm}={_arm_label(arms_state.get(arm) or {})}" for arm in config.ARMS
            )

    for prefix in sorted(groups):
        print(f"\n{prefix} ({len(groups[prefix])})")
        for iid in groups[prefix]:
            line = f"  {iid}"
            if args.run_id:
                line = f"  {iid:<36} {annotations[iid]}"
            print(line)
    return 0


# ---------------------------------------------------------------------------
# doctor
# ---------------------------------------------------------------------------

def _cmd_doctor(args) -> int:
    hard_fail = False
    for name, verdict, detail in doctor.run_checks(eval_checks=not args.no_eval_checks):
        label = "OK" if verdict else ("WARN" if verdict is None else "FAIL")
        if verdict is False:
            hard_fail = True
        print(f"{label:<5}{name:<22}{detail}")

    if args.canary or args.probe_model:
        model = config.MODEL if args.probe_model else config.CANARY_MODEL
        print(f"\nrunning canary session (model {model})...")
        res = doctor.run_canary(model=model)
        if res["clean"]:
            print(f"canary: clean (session {res['session_id']})")
        else:
            hard_fail = True
            print(f"canary: DIRTY (session {res['session_id']})")
            if not res["result_ok"]:
                print(f"  session error: {res['error']}")
            audit = res["audit"]
            if audit is None:
                print("  transcript not found")
            else:
                if audit["violations"]:
                    print(f"  tool violations: {', '.join(audit['violations'])}")
                if audit["marker_warnings"]:
                    print(f"  injected-listing marker lines: {audit['marker_warnings']}")
    return 1 if hard_fail else 0


# ---------------------------------------------------------------------------
# vendor-instances
# ---------------------------------------------------------------------------

def _cmd_vendor_instances(args) -> int:
    try:
        count = instances.vendor_instances()
    except Exception as exc:  # noqa: BLE001 — network/datasets errors are arbitrary
        print(f"error: vendoring failed: {exc}")
        return 1
    print(f"vendored {count} instances -> {config.INSTANCES_JSON}")
    return 0


# ---------------------------------------------------------------------------
# run
# ---------------------------------------------------------------------------

def _write_stub_manifest(
    inst_dir: Path, run_id: str, iid: str, arm_list: tuple[str, ...], error: str
) -> None:
    """Record an orchestration failure so the instance still appears in scores.

    Every requested arm is marked ``failed(orchestration_error)``. Never
    overwrites an existing manifest — if harvest already produced one it
    carries real per-arm state that must win.
    """
    manifest_path = inst_dir / "manifest.json"
    if manifest_path.is_file():
        return
    inst_dir.mkdir(parents=True, exist_ok=True)
    manifest_path.write_text(
        json.dumps(
            {
                "run_id": run_id,
                "instance_id": iid,
                "orchestration_error": error,
                "arms": {
                    arm: {"status": "failed", "reason": "orchestration_error"}
                    for arm in arm_list
                },
            },
            indent=2,
        )
        + "\n",
        encoding="utf-8",
    )


def _cmd_run(args) -> int:
    known = _load_instances_or_explain()
    if known is None:
        return 1
    ids = _resolve_ids(args, known)
    if ids is None:
        return 1
    arm_list = _parse_arms(args.arms)
    if arm_list is None:
        return 1

    run_id = args.run_id or _default_run_id()
    ws_root = Path(args.workspace_root) if args.workspace_root else config.workspace_root()
    results_dir = config.RESULTS_DIR

    print(f"run {run_id}: {len(ids)} instance(s), arms: {', '.join(arm_list)}")
    completed_arms = 0
    requested_arms = len(ids) * len(arm_list)
    for index, iid in enumerate(ids, start=1):
        print(f"[{index}/{len(ids)}] {iid}: running...")
        try:
            state = arms.run_instance(
                run_id,
                known[iid],
                ws_root,
                arms=arm_list,
                claude_bin=args.claude_bin,
                timeout=args.timeout,
                retry_failed=args.retry_failed,
                cache_dir=ws_root / "cache" / "repos",
            )
            harvest.harvest_instance(
                ws_root / run_id / iid, run_id, known[iid], results_dir=results_dir
            )
        except (RuntimeError, OSError) as exc:
            print(f"[{index}/{len(ids)}] {iid}: error: {exc}")
            _write_stub_manifest(
                results_dir / run_id / iid, run_id, iid, arm_list, str(exc)
            )
            continue
        labels = []
        for arm in arm_list:
            arm_state = state["arms"][arm]
            labels.append(f"{arm}={_arm_label(arm_state)}")
            if arm_state["status"] == "completed":
                completed_arms += 1
        print(f"[{index}/{len(ids)}] {iid}: " + " ".join(labels))

    manifest_path = harvest.write_run_manifest(run_id, results_dir=results_dir)
    print(f"run manifest: {manifest_path}")
    print(
        f"summary: {completed_arms}/{requested_arms} requested arm sessions completed"
    )
    if completed_arms == requested_arms:
        return 0
    return 2 if completed_arms else 1


# ---------------------------------------------------------------------------
# validate-gold
# ---------------------------------------------------------------------------

def _cmd_validate_gold(args) -> int:
    known = _load_instances_or_explain()
    if known is None:
        return 1
    ids = _resolve_ids(args, known)
    if ids is None:
        return 1

    print(f"gold check: evaluating official patches for {len(ids)} instance(s)...")
    results = evaluate.gold_eval(
        args.run_id, ids, max_workers=args.max_workers, results_dir=config.RESULTS_DIR
    )
    resolved = 0
    for iid in sorted(results):
        verdict = results[iid]
        if verdict is True:
            resolved += 1
            print(f"  {iid}: resolved")
        elif verdict is False:
            print(f"  {iid}: UNRESOLVED")
        else:
            print(f"  {iid}: MISSING (no report.json — see harness_goldcheck.log)")
    all_ok = bool(results) and resolved == len(results)
    print(
        f"gold check: {resolved}/{len(results)} resolved — eval environment "
        + ("validated" if all_ok else "NOT validated")
    )
    return 0 if all_ok else 1


# ---------------------------------------------------------------------------
# evaluate
# ---------------------------------------------------------------------------

def _cmd_evaluate(args) -> int:
    results_dir = config.RESULTS_DIR
    run_dir = results_dir / args.run_id
    if not run_dir.is_dir():
        print(f"error: no results for run {args.run_id} under {results_dir}")
        return 1
    arm_list = _parse_arms(args.arms)
    if arm_list is None:
        return 1

    successes = failures = 0
    for arm in arm_list:
        predictions_path, ids = evaluate.build_predictions(run_dir, arm)
        if not ids:
            print(f"[{arm}] no predictions (no solution patches in {run_dir})")
            failures += 1
            continue
        print(f"[{arm}] {len(ids)} prediction(s) -> {predictions_path}")
        rc = evaluate.run_official_eval(
            args.run_id, arm, ids,
            results_dir=results_dir, max_workers=args.max_workers,
        )
        if rc == 0:
            successes += 1
        else:
            failures += 1
            print(
                f"[{arm}] harness exit {rc} "
                f"(see {run_dir / 'eval' / f'harness_{arm}.log'})"
            )
        summary = evaluate.harvest_eval(args.run_id, arm, results_dir=results_dir)
        found = sum(1 for s in summary.values() if s["found"])
        resolved = sum(1 for s in summary.values() if s["resolved"])
        print(f"[{arm}] reports: {found}/{len(summary)} found, {resolved} resolved")

    _scores_json, scores_md = report.write_reports(args.run_id, results_dir=results_dir)
    index_path = report.refresh_index(results_dir=results_dir)
    print(f"scores: {scores_md}")
    print(f"index: {index_path}")
    if failures:
        return 2 if successes else 1
    return 0


# ---------------------------------------------------------------------------
# report
# ---------------------------------------------------------------------------

def _cmd_report(args) -> int:
    results_dir = config.RESULTS_DIR
    if not (results_dir / args.run_id).is_dir():
        print(f"error: no results for run {args.run_id} under {results_dir}")
        return 1
    _scores_json, scores_md = report.write_reports(args.run_id, results_dir=results_dir)
    report.refresh_index(results_dir=results_dir)
    print(f"scores: {scores_md}\n")
    text = scores_md.read_text(encoding="utf-8")
    marker = text.find("## Aggregates")
    if marker != -1:
        print(text[marker:].rstrip())
    return 0


# ---------------------------------------------------------------------------
# parser
# ---------------------------------------------------------------------------

def _add_instance_selection(sub: argparse.ArgumentParser) -> None:
    group = sub.add_mutually_exclusive_group(required=True)
    group.add_argument(
        "--instances", nargs="+", metavar="ID", default=[],
        help="exact instance ids to process",
    )
    group.add_argument(
        "--all", action="store_true", help="process all 45 benchmark instances"
    )


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        prog="fvk_bench",
        description="3-arm (baseline/fvk/control) Claude Code benchmark over SWE-bench Verified",
    )
    sub = parser.add_subparsers(dest="command", required=True)

    p = sub.add_parser("list", help="list the 45 instance ids grouped by repo")
    p.add_argument("--run-id", help="annotate each instance with its arm statuses from this run")
    p.set_defaults(func=_cmd_list)

    p = sub.add_parser("doctor", help="preflight checks (and optional session canary)")
    p.add_argument("--canary", action="store_true",
                   help="run a cheap real session and audit its transcript")
    p.add_argument("--probe-model", action="store_true",
                   help="run the canary with the pinned production model instead")
    p.add_argument("--no-eval-checks", action="store_true",
                   help="relax evaluation-only requirements (docker) to warnings")
    p.set_defaults(func=_cmd_doctor)

    p = sub.add_parser("vendor-instances",
                       help="download and vendor instance metadata (network + datasets)")
    p.set_defaults(func=_cmd_vendor_instances)

    p = sub.add_parser("run", help="run benchmark arms for selected instances")
    _add_instance_selection(p)
    p.add_argument("--run-id", help="run identifier (default: <utc-timestamp>-<hostname>); reuse to resume")
    p.add_argument("--arms", default=",".join(config.ARMS),
                   help=f"comma-separated arms to run (default: {','.join(config.ARMS)})")
    p.add_argument("--retry-failed", action="store_true",
                   help="re-run arms previously marked failed")
    p.add_argument("--claude-bin", default="claude", help="claude binary to invoke")
    p.add_argument("--workspace-root", help="override the workspace root directory")
    p.add_argument("--timeout", type=int, default=config.ARM_TIMEOUT_SECONDS,
                   help="per-arm wall-clock timeout in seconds")
    p.set_defaults(func=_cmd_run)

    p = sub.add_parser("validate-gold",
                       help="verify the eval environment resolves the official gold patches")
    p.add_argument("--run-id", required=True)
    _add_instance_selection(p)
    p.add_argument("--max-workers", type=int, default=4)
    p.set_defaults(func=_cmd_validate_gold)

    p = sub.add_parser("evaluate", help="score harvested patches with the official harness")
    p.add_argument("--run-id", required=True)
    p.add_argument("--arms", default=",".join(config.ARMS),
                   help="comma-separated arms to evaluate")
    p.add_argument("--max-workers", type=int, default=4)
    p.set_defaults(func=_cmd_evaluate)

    p = sub.add_parser("report", help="write scores.json/scores.md and refresh the index")
    p.add_argument("--run-id", required=True)
    p.set_defaults(func=_cmd_report)

    return parser


def main(argv: list[str] | None = None) -> int:
    args = build_parser().parse_args(argv)
    return args.func(args)

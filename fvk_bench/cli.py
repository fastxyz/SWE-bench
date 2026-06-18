"""Command-line interface for the fvk benchmark.

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
machine), so a single problem, one batch, or a selected full set can be
processed incrementally.
"""

import argparse
import json
import socket
import subprocess
import threading
import time
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path

from fvk_bench import (
    arms, batches, codex_runner, config, doctor, evaluate, harvest, instances,
    report, scaffold,
)


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


def _manifest_arms(run_dir: Path) -> tuple[str, ...]:
    """Return requested arms recorded for a run, falling back to all arms."""
    manifest_path = run_dir / "run_manifest.json"
    if not manifest_path.is_file():
        return config.ARMS
    try:
        manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    except (ValueError, OSError):
        return config.ARMS
    raw = manifest.get("arms")
    if isinstance(raw, list):
        arms = tuple(a for a in raw if a in config.ARMS)
        if arms:
            return arms
    return config.ARMS


def _manifest_dataset(run_dir: Path) -> str:
    """Resolve the dataset for a completed run, portably, from its manifest."""
    manifest_path = run_dir / "run_manifest.json"
    if manifest_path.is_file():
        try:
            m = json.loads(manifest_path.read_text(encoding="utf-8"))
        except ValueError:
            m = {}
        iset = m.get("instance_set")
        if iset in config.REGISTRY:
            return config.resolve_dataset(iset)
        if m.get("dataset"):  # legacy manifest recorded a literal dataset name
            return m["dataset"]
    return config.resolve_dataset(config.DEFAULT_INSTANCE_SET)


def _resolve_selection(args, known: dict) -> list[str] | None:
    """Resolve the --instances|--all|--batch selection against the loaded set."""
    if args.all:
        return sorted(known)
    if args.batch:
        try:
            ids = list(
                batches.batch_instances(args.batch, instance_ids=tuple(sorted(known)))
            )
        except KeyError as exc:
            print(f"error: {exc.args[0]}")
            return None
    else:
        ids = list(dict.fromkeys(args.instances))  # de-dup, keep order
    unknown = [iid for iid in ids if iid not in known]
    if unknown:
        print("error: unknown instance ids: " + ", ".join(unknown))
        instance_set = getattr(args, "instance_set", config.DEFAULT_INSTANCE_SET)
        print(
            "hint: "
            f"`python -m fvk_bench list --instance-set {instance_set}` "
            "shows the available benchmark instances"
        )
        return None
    return ids


def _load_instances_or_explain(instance_set: str = config.DEFAULT_INSTANCE_SET) -> dict | None:
    try:
        return instances.load_instances(instance_set=instance_set)
    except (RuntimeError, OSError) as exc:
        print(f"error: cannot load instance metadata: {exc}")
        print(
            "hint: run "
            f"`python -m fvk_bench vendor-instances --instance-set {instance_set}` first"
        )
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
    all_ids: list[str]
    if args.instance_set == "fvk45":
        try:
            all_ids = instances.submodule_instance_ids()
        except RuntimeError as exc:
            print(f"error: {exc}")
            return 1
    else:
        known = _load_instances_or_explain(args.instance_set)
        if known is None:
            return 1
        all_ids = sorted(known)
    ids = list(all_ids)
    if args.batch:
        try:
            members = set(
                batches.batch_instances(args.batch, instance_ids=tuple(all_ids))
            )
        except KeyError as exc:
            print(f"error: {exc.args[0]}")
            return 1
        ids = [iid for iid in ids if iid in members]

    groups: dict[str, list[str]] = {}
    for iid in ids:
        groups.setdefault(iid.rsplit("-", 1)[0], []).append(iid)
    print(f"{len(ids)} instances across {len(groups)} repos")

    batch_of = {}
    if args.instance_set == "fvk45":
        batch_of = {
            iid: name for name, batch_ids in batches.BATCHES.items() for iid in batch_ids
        }
    else:
        ordered_ids = tuple(all_ids)
        scheme = config.REGISTRY[args.instance_set].batch_scheme
        for name in batches.batch_names_for_scheme(scheme):
            try:
                for iid in batches.batch_instances(name, instance_ids=ordered_ids):
                    batch_of[iid] = name
            except KeyError:
                pass
    annotations: dict[str, str] = {}
    annotation_arms = config.ARMS
    if args.run_id:
        run_dir = config.RESULTS_DIR / args.run_id
        annotation_arms = _manifest_arms(run_dir)
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
                f"{arm}={_arm_label(arms_state.get(arm) or {})}" for arm in annotation_arms
            )

    for prefix in sorted(groups):
        print(f"\n{prefix} ({len(groups[prefix])})")
        for iid in groups[prefix]:
            extras = []
            if iid in batch_of:
                extras.append(f"[{batch_of[iid]}]")
            if args.run_id:
                extras.append(annotations[iid])
            if extras:
                print(f"  {iid:<36} " + " ".join(extras))
            else:
                print(f"  {iid}")
    return 0


# ---------------------------------------------------------------------------
# doctor
# ---------------------------------------------------------------------------

def _cmd_doctor(args) -> int:
    hard_fail = False
    for name, verdict, detail in doctor.run_checks(
        eval_checks=not args.no_eval_checks,
        agent=args.agent,
        claude_bin=args.claude_bin,
        codex_bin=args.codex_bin,
    ):
        label = "OK" if verdict else ("WARN" if verdict is None else "FAIL")
        if verdict is False:
            hard_fail = True
        print(f"{label:<5}{name:<22}{detail}")

    if args.canary or args.probe_model:
        if args.agent == "codex":
            model = config.CODEX_MODEL
            print(f"\nrunning codex canary session (model {model})...")
            res = doctor.run_codex_canary(model=model, codex_bin=args.codex_bin)
        else:
            model = config.MODEL if args.probe_model else config.CANARY_MODEL
            print(f"\nrunning canary session (model {model})...")
            res = doctor.run_canary(model=model, claude_bin=args.claude_bin)
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
                marker_warnings = audit.get("marker_warnings") or []
                if marker_warnings:
                    print(f"  injected-listing marker lines: {audit['marker_warnings']}")
                exec_warnings = audit.get("exec_warnings") or []
                if exec_warnings:
                    print(f"  forbidden execution attempts: {exec_warnings}")
    return 1 if hard_fail else 0


# ---------------------------------------------------------------------------
# vendor-instances
# ---------------------------------------------------------------------------

def _cmd_vendor_instances(args) -> int:
    try:
        count = instances.vendor_instances(instance_set=args.instance_set)
    except Exception as exc:  # noqa: BLE001 — network/datasets errors are arbitrary
        print(f"error: vendoring failed: {exc}")
        return 1
    out_path = config.REGISTRY[args.instance_set].data_file
    print(f"vendored {count} instances -> {out_path}")
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
    known = _load_instances_or_explain(args.instance_set)
    if known is None:
        return 1
    ids = _resolve_selection(args, known)
    if ids is None:
        return 1
    arm_list = _parse_arms(args.arms)
    if arm_list is None:
        return 1

    run_id = args.run_id or _default_run_id()
    ws_root = Path(args.workspace_root) if args.workspace_root else config.workspace_root()
    results_dir = config.RESULTS_DIR
    cache_dir = ws_root / "cache" / "repos"
    max_parallel = max(1, args.max_parallel)

    print(f"run {run_id}: {len(ids)} instance(s), arms: {', '.join(arm_list)}")

    # Pre-warm the mirror cache sequentially so concurrent workers never race
    # to clone the same repo. Failures are non-fatal: the worker retries the
    # clone and reports the real error through the per-instance stub path.
    for repo in dict.fromkeys(known[iid].repo for iid in ids):
        try:
            scaffold.ensure_mirror(repo, cache_dir)
        except (RuntimeError, OSError) as exc:
            print(f"warning: mirror pre-warm failed for {repo}: {exc}")

    # The fvk arm delivers its methodology through the installed Codex skill, not
    # workspace files. Install it once up front from the pinned submodule so the
    # manifest's submodule sha records exactly which FVK version every fvk session
    # ran against. A failed install is fatal: the fvk arm cannot run without it.
    if args.agent == "codex" and "fvk" in arm_list:
        try:
            dest = codex_runner.install_fvk_skill()
        except (RuntimeError, OSError, subprocess.CalledProcessError) as exc:
            print(f"error: fvk skill install failed: {exc}")
            return 1
        print(f"fvk skill installed -> {dest}")

    total = len(ids)
    print_lock = threading.Lock()

    def _run_one(numbered: tuple[int, str]) -> tuple[str, dict | None]:
        """Run + harvest one instance; returns (iid, state) with None on error.

        Runs on a worker thread: no chdir, no shared mutable state beyond the
        print lock; workspace/results paths are disjoint per instance.
        """
        index, iid = numbered
        with print_lock:
            print(f"[{index}/{total}] {iid}: running...")
        try:
            state = arms.run_instance(
                run_id,
                known[iid],
                ws_root,
                arms=arm_list,
                agent=args.agent,
                claude_bin=args.claude_bin,
                codex_bin=args.codex_bin,
                timeout=args.timeout,
                retry_failed=args.retry_failed,
                cache_dir=cache_dir,
            )
            harvest.harvest_instance(
                ws_root / run_id / iid, run_id, known[iid], results_dir=results_dir
            )
        except (RuntimeError, OSError) as exc:
            with print_lock:
                print(f"[{index}/{total}] {iid}: error: {exc}")
            _write_stub_manifest(
                results_dir / run_id / iid, run_id, iid, arm_list, str(exc)
            )
            return iid, None
        labels = " ".join(f"{arm}={_arm_label(state['arms'][arm])}" for arm in arm_list)
        with print_lock:
            print(f"[{index}/{total}] {iid}: {labels}")
        return iid, state

    # Rolling execution: all instances are queued up front; at most
    # max_parallel run at once and each finished slot starts the next.
    with ThreadPoolExecutor(max_workers=max_parallel) as ex:
        results = list(ex.map(_run_one, enumerate(ids, start=1)))

    completed_arms = sum(
        1
        for _iid, state in results
        if state is not None
        for arm in arm_list
        if state["arms"][arm]["status"] == "completed"
    )
    requested_arms = len(ids) * len(arm_list)
    manifest_path = harvest.write_run_manifest(
        run_id, results_dir=results_dir,
        extra={
            "max_parallel": max_parallel,
            "agent": args.agent,
            "arms": list(arm_list),
            "instance_set": args.instance_set,
            "instances": ids,
            "claude_bin": args.claude_bin,
            "codex_bin": args.codex_bin,
        },
    )
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
    known = _load_instances_or_explain(args.instance_set)
    if known is None:
        return 1
    ids = _resolve_selection(args, known)
    if ids is None:
        return 1

    print(f"gold check: evaluating official patches for {len(ids)} instance(s)...")
    results = evaluate.gold_eval(
        args.run_id, ids,
        dataset=config.resolve_dataset(args.instance_set),
        max_workers=args.max_workers, results_dir=config.RESULTS_DIR,
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
    if args.arms is None:
        arm_list = _manifest_arms(run_dir)
    else:
        arm_list = _parse_arms(args.arms)
        if arm_list is None:
            return 1

    dataset = _manifest_dataset(run_dir)
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
            dataset=dataset,
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
        "--all", action="store_true", help="process every instance in --instance-set"
    )
    group.add_argument(
        "--batch", metavar="NAME",
        help=f"process one batch ({', '.join(sorted(batches.BATCHES))}, verified001..verified050, or multilingual001..multilingual030)",
    )


def _add_instance_set(sub: argparse.ArgumentParser) -> None:
    sub.add_argument(
        "--instance-set",
        choices=config.INSTANCE_SETS,
        default=config.DEFAULT_INSTANCE_SET,
        help=f"which vendored instance set to use (default: {config.DEFAULT_INSTANCE_SET})",
    )


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        prog="fvk_bench",
        description="baseline/fvk/control benchmark over SWE-bench Verified",
    )
    sub = parser.add_subparsers(dest="command", required=True)

    p = sub.add_parser("list", help="list instance ids grouped by repo")
    _add_instance_set(p)
    p.add_argument("--run-id", help="annotate each instance with its arm statuses from this run")
    p.add_argument("--batch", metavar="NAME",
                   help=f"only list one batch ({', '.join(sorted(batches.BATCHES))}, verified001..verified050, or multilingual001..multilingual030)")
    p.set_defaults(func=_cmd_list)

    p = sub.add_parser("doctor", help="preflight checks (and optional session canary)")
    p.add_argument("--agent", choices=config.AGENTS, default=config.DEFAULT_AGENT,
                   help=f"which agent CLI to preflight (default: {config.DEFAULT_AGENT})")
    p.add_argument("--claude-bin", default="claude", help="claude binary to invoke")
    p.add_argument("--codex-bin", default="codex", help="codex binary to invoke")
    p.add_argument("--canary", action="store_true",
                   help="run a cheap real session and audit its transcript")
    p.add_argument("--probe-model", action="store_true",
                   help="run the canary with the pinned production model instead")
    p.add_argument("--no-eval-checks", action="store_true",
                   help="relax evaluation-only requirements (docker) to warnings")
    p.set_defaults(func=_cmd_doctor)

    p = sub.add_parser("vendor-instances",
                       help="download and vendor instance metadata (network + datasets)")
    _add_instance_set(p)
    p.set_defaults(func=_cmd_vendor_instances)

    p = sub.add_parser("run", help="run benchmark arms for selected instances")
    _add_instance_set(p)
    _add_instance_selection(p)
    p.add_argument("--run-id", help="run identifier (default: <utc-timestamp>-<hostname>); reuse to resume")
    p.add_argument("--arms", default=",".join(config.ARMS),
                   help=f"comma-separated arms to run (default: {','.join(config.ARMS)})")
    p.add_argument("--retry-failed", action="store_true",
                   help="re-run arms previously marked failed")
    p.add_argument("--agent", choices=config.AGENTS, default=config.DEFAULT_AGENT,
                   help=f"which agent CLI drives the arms (default: {config.DEFAULT_AGENT})")
    p.add_argument("--claude-bin", default="claude", help="claude binary to invoke")
    p.add_argument("--codex-bin", default="codex", help="codex binary to invoke (when --agent codex)")
    p.add_argument("--workspace-root", help="override the workspace root directory")
    p.add_argument("--timeout", type=int, default=config.ARM_TIMEOUT_SECONDS,
                   help="per-arm wall-clock timeout in seconds")
    p.add_argument("--max-parallel", type=int, default=1,
                   help="run up to N instances concurrently (default 1 = sequential; "
                        "arms within an instance always stay sequential)")
    p.set_defaults(func=_cmd_run)

    p = sub.add_parser("validate-gold",
                       help="verify the eval environment resolves the official gold patches")
    p.add_argument("--run-id", required=True)
    _add_instance_set(p)
    _add_instance_selection(p)
    p.add_argument("--max-workers", type=int, default=4)
    p.set_defaults(func=_cmd_validate_gold)

    p = sub.add_parser("evaluate", help="score harvested patches with the official harness")
    p.add_argument("--run-id", required=True)
    p.add_argument("--arms", default=None,
                   help="comma-separated arms to evaluate (default: run manifest arms)")
    p.add_argument("--max-workers", type=int, default=4)
    p.set_defaults(func=_cmd_evaluate)

    p = sub.add_parser("report", help="write scores.json/scores.md and refresh the index")
    p.add_argument("--run-id", required=True)
    p.set_defaults(func=_cmd_report)

    return parser


def main(argv: list[str] | None = None) -> int:
    args = build_parser().parse_args(argv)
    return args.func(args)

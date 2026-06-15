"""Scoring reports: per-run scores.json / scores.md and the cross-run index.

Reads only harvested artifacts under ``results/<run_id>/`` (manifests, solution
patches, copied eval reports) — never workspaces or harness logs — so reports
can be regenerated from a results tree alone on any machine.

Reporting discipline (from the design spec): every instance in the run × every
arm appears in the table; failed or skipped arms show their status and reason
explicitly, empty patches are flagged explicitly, and per-arm resolved counts
are stated over the evaluated instances — those with eval reports plus
completed arms whose empty patch scores unresolved without ever reaching the
harness (producing nothing IS that arm's answer). Cross-machine
comparisons belong at the aggregate level (resolved counts, flip counts), so
the aggregates section carries baseline→fvk / baseline→control flips with
direction and the fvk-vs-control delta.
"""

import json
from pathlib import Path

from fvk_bench import config, evaluate


def _load_json(path: Path) -> dict | None:
    """Parse a JSON file; None when absent or malformed (never raises)."""
    if not path.is_file():
        return None
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except (ValueError, OSError):
        return None
    return data if isinstance(data, dict) else None


def _eval_summary(inst_dir: Path, arm: str) -> dict | None:
    """Reduce a copied ``<arm>.report.json`` to {resolved, ftp, ptp} or None."""
    data = _load_json(inst_dir / "eval" / f"{arm}.report.json")
    if data is None:
        return None
    s = evaluate.summarize_report(data, inst_dir.name)
    return {
        "resolved": s["resolved"],
        "ftp": f"{s['ftp_pass']}/{s['ftp_total']}",
        "ptp": f"{s['ptp_pass']}/{s['ptp_total']}",
    }


def _aggregates(instances: dict) -> dict:
    """Per-arm resolved counts, directional flips, and the fvk/control delta.

    Counts are over evaluated instances for that arm: those with an eval
    report, plus completed arms whose empty patch is scored unresolved by
    :func:`collect_scores`. Failed/skipped arms and completed arms with a
    patch but no report (eval not run yet, or a harness error) stay out of
    the denominator. Flips compare only instances where BOTH arms are
    evaluated (an unevaluated arm can neither gain nor lose an instance).
    """
    arms_agg: dict = {}
    for arm in config.ARMS:
        evaluated = resolved = 0
        for per_arm in instances.values():
            ev = (per_arm.get(arm) or {}).get("eval")
            if ev is not None and isinstance(ev.get("resolved"), bool):
                evaluated += 1
                resolved += 1 if ev["resolved"] else 0
        arms_agg[arm] = {"resolved": resolved, "evaluated": evaluated}

    def flips(src: str, dst: str) -> dict:
        up: list[str] = []
        down: list[str] = []
        for iid in sorted(instances):
            per_arm = instances[iid]
            src_ev = (per_arm.get(src) or {}).get("eval")
            dst_ev = (per_arm.get(dst) or {}).get("eval")
            if not src_ev or not dst_ev:
                continue
            s, d = src_ev.get("resolved"), dst_ev.get("resolved")
            if not isinstance(s, bool) or not isinstance(d, bool):
                continue
            if d and not s:
                up.append(iid)
            elif s and not d:
                down.append(iid)
        return {"up": up, "down": down}

    return {
        "arms": arms_agg,
        "flips": {
            "baseline_to_fvk": flips("baseline", "fvk"),
            "baseline_to_control": flips("baseline", "control"),
        },
        "fvk_vs_control_delta": (
            arms_agg["fvk"]["resolved"] - arms_agg["control"]["resolved"]
        ),
    }


def collect_scores(run_id: str, results_dir: Path = config.RESULTS_DIR) -> dict:
    """Collect per-instance × per-arm scores from a harvested run directory.

    Every directory under ``results/<run_id>/`` containing a ``manifest.json``
    is an instance. For each arm the result carries the manifest's status /
    reason / session_id / num_turns / duration_seconds, an ``empty_patch``
    flag (solution patch absent or zero bytes), and the eval summary parsed
    from the copied ``<arm>.report.json``.

    A COMPLETED arm with an empty patch never reaches the harness (empty
    predictions are filtered), so no report exists — but producing nothing is
    that arm's answer: its eval is synthesized as
    ``{"resolved": False, "ftp": "0/0", "ptp": "0/0", "reason": "empty_patch"}``
    so it counts as evaluated-and-unresolved in aggregates and flips. All
    other report-less arms (failed/skipped, or completed with a patch whose
    eval has not run / errored) keep ``eval=None`` (not evaluated).
    """
    run_dir = Path(results_dir) / run_id
    instances: dict = {}
    if run_dir.is_dir():
        for inst_dir in sorted(p for p in run_dir.iterdir() if p.is_dir()):
            manifest = _load_json(inst_dir / "manifest.json")
            if manifest is None:
                continue
            arms_state = manifest.get("arms") or {}
            per_arm: dict = {}
            for arm in config.ARMS:
                state = arms_state.get(arm) or {}
                patch = inst_dir / "solutions" / f"solution_{arm}.patch"
                empty_patch = not patch.is_file() or patch.stat().st_size == 0
                ev = _eval_summary(inst_dir, arm)
                if ev is None and empty_patch and state.get("status") == "completed":
                    ev = {
                        "resolved": False,
                        "ftp": "0/0",
                        "ptp": "0/0",
                        "reason": "empty_patch",
                    }
                per_arm[arm] = {
                    "status": state.get("status"),
                    "reason": state.get("reason"),
                    "session_id": state.get("session_id"),
                    "num_turns": state.get("num_turns"),
                    "duration_seconds": state.get("duration_seconds"),
                    "empty_patch": empty_patch,
                    "eval": ev,
                }
            instances[inst_dir.name] = per_arm
    return {
        "run_id": run_id,
        "instances": instances,
        "aggregates": _aggregates(instances),
    }


def _status_cell(arm_scores: dict) -> str:
    status = arm_scores.get("status") or "—"
    if arm_scores.get("reason"):
        status += f"({arm_scores['reason']})"
    # Flag empty patches only on completed arms: there the model genuinely
    # produced nothing (scores unresolved); on failed/skipped arms the status
    # itself already explains the missing patch.
    if arm_scores.get("empty_patch") and arm_scores.get("status") == "completed":
        status += " [empty patch]"
    return status


def _resolved_glyph(resolved) -> str:
    if resolved is True:
        return "✓"
    if resolved is False:
        return "✗"
    return "—"


def render_scores_md(scores: dict, run_manifest: dict | None) -> str:
    """Render the human-readable scores markdown for one run.

    Per-instance table (instances sorted; one status/resolved/FTP/PTP column
    group per arm — failed or skipped arms appear as their status, never
    omitted) followed by the aggregates section.
    """
    lines = [f"# Scores — run {scores['run_id']}", ""]
    if run_manifest:
        host = (run_manifest.get("host") or {}).get("hostname") or "unknown"
        invocation = run_manifest.get("invocation") or {}
        agent = run_manifest.get("agent") or config.DEFAULT_AGENT
        model = invocation.get("model") or "unknown"
        effort = invocation.get("effort")
        header = [
            f"- host: {host}",
            f"- agent: {agent}",
            f"- model: {model}",
        ]
        if effort:
            header.append(f"- effort: {effort}")
        version_key = f"{agent}_version"
        version_label = version_key.replace("_", " ")
        header += [
            f"- {version_label}: {run_manifest.get(version_key) or 'unknown'}",
            f"- created: {run_manifest.get('created_utc') or 'unknown'}",
            "",
        ]
        lines += header

    header = ["instance"]
    for arm in config.ARMS:
        header += [f"{arm} status", f"{arm} resolved", f"{arm} FTP", f"{arm} PTP"]
    lines.append("| " + " | ".join(header) + " |")
    lines.append("|" + "---|" * len(header))
    instances = scores.get("instances") or {}
    for iid in sorted(instances):
        row = [iid]
        for arm in config.ARMS:
            arm_scores = instances[iid].get(arm) or {}
            ev = arm_scores.get("eval")
            row.append(_status_cell(arm_scores))
            if ev is None:
                row += ["—", "—", "—"]
            else:
                row += [_resolved_glyph(ev.get("resolved")), ev["ftp"], ev["ptp"]]
        lines.append("| " + " | ".join(row) + " |")

    agg = scores["aggregates"]
    lines += ["", "## Aggregates", ""]
    for arm in config.ARMS:
        counts = agg["arms"][arm]
        lines.append(
            f"- {arm} resolved: {counts['resolved']}/{counts['evaluated']}"
            " (over evaluated instances; completed empty patches score unresolved)"
        )
    for key, label in (
        ("baseline_to_fvk", "baseline→fvk"),
        ("baseline_to_control", "baseline→control"),
    ):
        fl = agg["flips"][key]
        up = ", ".join(fl["up"]) or "none"
        down = ", ".join(fl["down"]) or "none"
        lines.append(
            f"- flips {label}: +{len(fl['up'])}/-{len(fl['down'])}"
            f" (up: {up}; down: {down})"
        )
    lines.append(f"- fvk vs control resolved delta: {agg['fvk_vs_control_delta']:+d}")
    return "\n".join(lines) + "\n"


def write_reports(
    run_id: str, results_dir: Path = config.RESULTS_DIR
) -> tuple[Path, Path]:
    """Write ``scores.json`` and ``scores.md`` under ``results/<run_id>/``.

    Idempotent — both files are regenerated from the harvested tree on every
    call. Returns ``(scores_json_path, scores_md_path)``.
    """
    results_dir = Path(results_dir)
    run_dir = results_dir / run_id
    run_dir.mkdir(parents=True, exist_ok=True)
    scores = collect_scores(run_id, results_dir=results_dir)
    run_manifest = _load_json(run_dir / "run_manifest.json")
    json_path = run_dir / "scores.json"
    md_path = run_dir / "scores.md"
    json_path.write_text(json.dumps(scores, indent=2) + "\n", encoding="utf-8")
    md_path.write_text(render_scores_md(scores, run_manifest), encoding="utf-8")
    return json_path, md_path


def refresh_index(results_dir: Path = config.RESULTS_DIR) -> Path:
    """Rewrite ``results/INDEX.md`` listing every run with a run manifest.

    One table row per run directory (sorted by name) that contains a
    ``run_manifest.json``: run id, host, model, instance count, per-arm
    resolved counts (from ``scores.json`` aggregates when present, else "—"),
    and creation timestamp. Runs without scores yet are still listed so
    in-flight work is discoverable.
    """
    results_dir = Path(results_dir)
    results_dir.mkdir(parents=True, exist_ok=True)

    rows: list[list[str]] = []
    for run_dir in sorted(p for p in results_dir.iterdir() if p.is_dir()):
        manifest = _load_json(run_dir / "run_manifest.json")
        if manifest is None:
            continue
        host = (manifest.get("host") or {}).get("hostname") or "unknown"
        model = (manifest.get("invocation") or {}).get("model") or "unknown"
        created = manifest.get("created_utc") or "unknown"
        n_instances = sum(
            1
            for d in run_dir.iterdir()
            if d.is_dir() and (d / "manifest.json").is_file()
        )
        per_arm = {arm: "—" for arm in config.ARMS}
        scores = _load_json(run_dir / "scores.json")
        if scores is not None:
            arms_agg = (scores.get("aggregates") or {}).get("arms") or {}
            for arm in config.ARMS:
                counts = arms_agg.get(arm)
                if isinstance(counts, dict) and "resolved" in counts:
                    per_arm[arm] = f"{counts['resolved']}/{counts['evaluated']}"
        rows.append(
            [
                run_dir.name,
                host,
                model,
                str(n_instances),
                *(per_arm[arm] for arm in config.ARMS),
                created,
            ]
        )

    header = [
        "run_id",
        "host",
        "model",
        "instances",
        *(f"{arm} resolved" for arm in config.ARMS),
        "created_utc",
    ]
    lines = [
        "# fvk_bench results index",
        "",
        "| " + " | ".join(header) + " |",
        "|" + "---|" * len(header),
    ]
    lines += ["| " + " | ".join(row) + " |" for row in rows]
    out = results_dir / "INDEX.md"
    out.write_text("\n".join(lines) + "\n", encoding="utf-8")
    return out

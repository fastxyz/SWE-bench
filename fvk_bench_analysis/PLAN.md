# FVK Bench — Post-Run Failure Analysis Plan

*Status: LOCKED (2026-06-13/14). This document is the spec that drives the whole analysis run. Extended to batch5 on 2026-06-14 (7 → 11 instances; method unchanged).*

## 0. Objective

Post-mortem the instances where the **fvk arm failed** in batch1–5. For each instance:

1. Establish the **true root cause** (read off the oracle/gold patch + hidden tests): where the bug is and why, and what the correct fix is.
2. Measure whether that root cause is **present (probably hidden) in the FVK-generated artifacts** — or **missing**.

Aggregate the per-instance verdicts into the number we actually care about: **FVK's improvement headroom** — if *k* of *N* failing instances already have their root cause latent in the artifacts FVK produced, then a better FVK (one that *surfaces and de-noises* the information it already generates) could plausibly flip ~*k* of today's failures.

This is a measurement study, not a verification study. We are answering: *does the information FVK generates already contain the root cause?*

## 1. Key facts established before analysis (ground the agents in these)

- **The fvk arm is not an independent solver.** It is a *forked resume* of the frozen **baseline** session. It starts from **V1 = base commit + baseline's patch**, and its prompt says: *"Apply the FVK methodology to audit that fix, then improve or confirm it."* Tools are `Read, Write, Edit, Glob, Grep`. It has **no execution environment** — it is told to write `kompile`/`kprove`/test commands into artifacts and reason about expected outcomes, **never running them**. (Source: `fvk_bench/prompts/fvk.md`, `fvk_bench/arms.py`, `fvk_bench/config.py`.)
- **Across batch1–5, fvk and baseline verdicts are identical — zero flips.** FVK never converted a baseline failure into a pass (and never broke a baseline pass). This is the macro context for the entire study and belongs at the top of `SYNTHESIS.md`. *(Consequence: a "calibration sample" of an FVK win does not exist — there are none.)*
- **What the fvk arm produces per instance** (the audit target), under `results/<batch_run_id>/<instance_id>/`:
  - `fvk/SPEC.md`, `fvk/FINDINGS.md`, `fvk/PROOF_OBLIGATIONS.md`, `fvk/PROOF.md`, `fvk/schema_index.k`, `fvk/schema_index-spec.k` (names vary per instance) — **the first-hand formal artifacts**.
  - `reports/fvk_notes.md` — the agent's decision log.
  - `solutions/solution_baseline.patch` (= V1) and `solutions/solution_fvk.patch` (= final fvk output).
  - `transcripts/fvk.jsonl.gz` — the fvk session transcript (gzipped; `zcat`/`gunzip` to read).
  - `eval/fvk.report.json` — pass/fail + which FAIL_TO_PASS tests failed.

## 2. The 11 fvk-failing instances (process in this order)

| # | instance_id | batch run-id (dir under `results/`) |
|---|-------------|--------------------------------------|
| 1 | `astropy__astropy-13398`     | `batch1-XC-MINI-PRO-AHP` |
| 2 | `django__django-10554`       | `batch1-XC-MINI-PRO-AHP` |
| 3 | `django__django-12325`       | `batch1-XC-MINI-PRO-AHP` |
| 4 | `django__django-13212`       | `batch1-XC-MINI-PRO-AHP` |
| 5 | `django__django-16263`       | `batch3-XC-MINI-PRO-AHP-260613154559` |
| 6 | `pytest-dev__pytest-10356`   | `batch4-XC-MINI-PRO-AHP-260613182909` |
| 7 | `sphinx-doc__sphinx-9229`    | `batch4-XC-MINI-PRO-AHP-260613182909` |
| 8 | `pydata__xarray-6992`        | `batch5-XC-MINI-PRO-AHP-260614105258` |
| 9 | `sympy__sympy-13852`         | `batch5-XC-MINI-PRO-AHP-260614105258` |
| 10 | `sympy__sympy-16597`        | `batch5-XC-MINI-PRO-AHP-260614105258` |
| 11 | `sympy__sympy-18199`        | `batch5-XC-MINI-PRO-AHP-260614105258` |

(batch2 had 0 fvk failures; batch5 added 4. `sphinx-doc__sphinx-11510` is excluded: its baseline failed audit, so the fvk arm never ran.)

## 3. Where to find each input (paths, relative to repo root)

- **Problem statement / metadata:** `fvk_bench/data/instances.json` (lookup by `instance_id`: `problem_statement`, `repo`, `base_commit`, `fail_to_pass_count`, `pass_to_pass_count`).
- **Oracle / gold patch:** `logs/run_evaluation/<batch_run_id>.goldcheck/gold/<instance_id>/patch.diff`. Gold test output: same dir, `test_output.txt`. *(If absent for a batch, fall back to the `third_party/swebench-fvk-reproducibility` submodule or the SWE-bench Verified dataset, and log the fallback in INCIDENTS.md.)*
- **FVK artifacts + transcript + patches:** under `results/<batch_run_id>/<instance_id>/` as listed in §1.
- **The FVK kit itself (for the primer):** `third_party/formal-verification-kit/`.

## 4. Verdict rubric (the core output, per instance)

Classify whether the root cause is present in the FVK artifacts:

- **STATED** — an artifact *explicitly names* the faulty thing or the correct-fix direction, but the agent didn't act on it (or acted wrongly). *Most improvable: the info was right there.*
- **BURIED** — the signal exists in **formal form** (a precondition the proof was *forced* to assume, an *undischargeable* obligation for a branch/case, a spec `claim` that *diverges* from documented intent, an invariant that does not actually hold) but was never surfaced as a finding / is drowned in noise. *Improvable via better surfacing + de-noising.*
- **MISSING** — no trace anywhere in the artifacts. For MISSING, add the honesty check: **was the root cause even derivable from the public data the fvk arm had?** (issue text, code, docstrings/informal spec, public or trivially-derivable tests). If *not* derivable from public data, the absence is **not** FVK's fault and must not be counted against it.

**Operational "present" test (controls hindsight):** a knowledgeable reader, *pointed at the cited spot*, would agree the excerpt encodes the faulty thing or the correct-fix direction — even if FVK never labeled it a finding. We are measuring *presence of information*, not claiming FVK would obviously have found it.

**Headroom accounting:** STATED or BURIED ⇒ counts toward headroom (improvable). MISSING-but-reachable ⇒ does not count, but is an FVK gap. MISSING-and-unreachable ⇒ excluded from the headroom denominator (information-theoretically out of reach).

## 5. Per-instance flow

**A · Root cause** (from oracle + hidden tests): exact bug location (file:line / function), why it is a bug, the correct fix, the bug *type*; plus a brief note on whether/how it is reachable from **public** data. This defines precisely what the latent signal should look like.

**B · Artifact audit** (the heart): hunt the root cause through the instance's `fvk/` artifacts (**first-hand first**) + `fvk_notes.md` + the transcript. Also diff `solution_baseline.patch` (V1) vs `solution_fvk.patch` to see whether fvk changed or merely confirmed V1. Decide the verdict (§4) with the **exact excerpt** where the signal appears, or a documented confirmed absence (state what was searched). Add a short, *general/transferable, no-exec* note on **how FVK could surface it**.

No verification phase. Recommendations stay prose-level and within the no-exec paradigm.

## 6. FVK primer (Phase 0) — a decoder ring, built carefully

The kit is rough ("vibe-coded"); a careless distillation would give every analyst a *wrong* model of FVK and corrupt every verdict. So the primer's purpose is narrow and explicit: **let an analyst recognize a root cause when it is hiding in FVK's formal idiom.** It must be:

- **Source-anchored** — every claim carries a quote + exact path into `third_party/formal-verification-kit/`; it tells readers to consult the primary source, it does not replace it.
- **Honest about roughness** — flags where the kit is vague/inconsistent/aspirational ("constructed, not machine-checked"; mini-X fragment semantics), so analysts don't mistake a *kit* limitation for an *analysis* finding.
- **Explicit about blind spots** — names bug classes that simply **won't** manifest in FVK artifacts, so MISSING verdicts are fair.
- **Task-shaped & tight**, with its most important section being *"how root causes manifest in artifacts"* (the tells: forced precondition → latent missing-precondition; undischarged obligation → latent unhandled case; spec/intent divergence → latent wrong behavior).
- **Versioned** — built once in Phase 0, then corrected if an instance reveals the kit behaves differently than the primer claims (sequential accumulation).

## 7. Subagent topology & sequencing

- **Orchestrator (main session):** writes these docs, dispatches Phase 0, then dispatches the **lead agents one at a time (one per instance)** (sequential — so a running tally and primer corrections accrue, and later cases get sharper). Keeps its own context slim: each lead **writes its own deliverables** and returns a ≤180-word summary.
- **Per-instance lead agent:** delegates gathering to its own sub-subagents (root-cause extractor; FVK-artifact forensics — runnable in parallel), then synthesizes, decides the verdict, and writes `ANALYSIS.md` + `evidence/`. (If it cannot spawn subagents, it does the gathering directly.)

## 8. Deliverables

```
fvk_bench_analysis/
  PLAN.md            ← this file
  README.md          ← index + running stated/buried/missing tally
  INCIDENTS.md       ← problems, choices, reasoning, with references (for traceability)
  _shared/
    fvk-primer.md    ← the decoder ring (Phase 0)
  <instance_id>/
    ANALYSIS.md      ← Root cause · What fvk did · Artifact audit (VERDICT + exact excerpt) · How FVK could surface it
    evidence/        ← oracle diff, the artifact excerpts that do/don't carry the signal, failing-test snippets
  SYNTHESIS.md       ← headroom (k/N present) · stated/buried/missing breakdown · which artifact types carry signal · the "zero flips" macro context · prose directions to improve FVK
```

## 9. Honesty & incident policy

- **No stretching for FVK.** MISSING and MISSING-unreachable are valid, useful conclusions. The point is a factual measurement of FVK's latent value.
- **Hindsight controlled** by the §4 "pointed-at-the-spot" rubric.
- **Incidents** (missing files, ambiguous verdicts, tooling failures) → `INCIDENTS.md` with clear references. Fix properly where possible; try alternatives before giving up. Stop only if a failure renders the run meaningless without user input — and even then, write down the incident, the choices considered, and the reasoning.

---

## Appendix A — Lead-agent prompt template (reused per instance)

> You are the **lead analyst for ONE instance** in a post-run study of the FVK arm of `fvk_bench`. Repo root `/home/xc/Projects/fastxyz-SWE-bench`. Read-only except you WRITE under `fvk_bench_analysis/<instance_id>/`. Do not modify code, results, or the submodule.
>
> INSTANCE `<instance_id>` · BATCH `<batch_run_id>`.
> First read `fvk_bench_analysis/PLAN.md` (esp. §3 paths, §4 rubric, §5 flow) and `fvk_bench_analysis/_shared/fvk-primer.md` (decoder).
> Background: the fvk arm forked the baseline session, started from V1 = base + baseline patch, was told to audit/improve with FVK, tools Read/Edit/Grep, **no execution**; it failed (baseline failed identically).
> GOAL: is the instance's TRUE root cause present (possibly hidden) in the FVK artifacts, or missing?
> Delegate gathering to your own subagents (parallel), then synthesize:
>  (1) Root-cause extractor — oracle patch + problem statement + gold test output → exact bug location, why, correct fix, bug type, public-data reachability.
>  (2) FVK-artifact forensics — read `fvk/*`, `reports/fvk_notes.md`, both patches, and mine `transcripts/fvk.jsonl.gz` → what FVK produced; did fvk change or confirm V1; any place the artifacts touch the root-cause region/condition.
> Decide VERDICT per PLAN §4 (STATED / BURIED / MISSING; if missing, reachable?). Apply the "pointed-at-the-spot" test; quote the EXACT excerpt for presence or document the confirmed absence.
> Be factual; do not stretch to credit FVK; MISSING is a fine conclusion.
> WRITE `ANALYSIS.md` (sections: 1 Root cause; 2 What the fvk arm did [V1 vs final + key artifact contents]; 3 Artifact audit — VERDICT + exact excerpt or documented absence; 4 How FVK could surface it [prose, general, no-exec, or "n/a — missing & unreachable"]) and `evidence/` (oracle diff, key artifact excerpts, failing-test snippet).
> If blocked (missing oracle/artifacts/transcript), try alternatives and record what you tried.
> RETURN (≤180 words): instance_id; one-line root cause; VERDICT; if missing, reachable?; counts-toward-headroom (yes/no); the single most important artifact excerpt location; any suggested primer correction; any incident. Do NOT paste the full analysis.

## Appendix B — Instance → batch map

See §2. Oracle dir = `logs/run_evaluation/<batch_run_id>.goldcheck/gold/<instance_id>/`.

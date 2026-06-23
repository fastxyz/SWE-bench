# scikit-learn__scikit-learn-11310

## Summary

**Severity:** Low — baseline adds `refit_time_` to the modern search base but
leaves the **deprecated `sklearn.grid_search` duplicate** of the same public
final-refit path without the attribute; the affected module is deprecated, so
the practical blast radius is small.

Baseline and FVK both passed the official SWE-bench evaluation for issue #11310,
with **different** patches. The issue example uses `sklearn.model_selection`, and
that is the only path the official test exercises — so baseline, gold, and the
harness all stop there. FVK located a **second public implementation of the same
feature** in the still-present deprecated `sklearn.grid_search` module by
**formalizing the refit-timing obligation as applying to every public search
implementation and auditing each one** — not by running more tests.

| Arm | [`test_search_cv_timing`](../verified500_analysis/scikit-learn__scikit-learn-11310/_materials/gold_test.patch) (model_selection only) | `refit_time_` on deprecated `grid_search` | Resolved (per issue) |
|---|---|---|---|
| baseline | resolved (official eval) | **absent** | yes |
| gold (human oracle) | resolved | **absent** | yes |
| **fvk** | resolved (official eval) | **present** | yes |

## 1. The issue and the real defect

**GitHub issue scikit-learn#11310** — *"Retrieving time to refit the estimator
in BaseSearchCV":* the user wants the wall-clock time of the final refit of the
best model on the full data after grid/random search, exposed as an attribute
`refit_time_`, because subtracting fold timings no longer works once `n_jobs != 1`
([`problem_statement.md`](../verified500_analysis/scikit-learn__scikit-learn-11310/_materials/problem_statement.md#L20)).

`BaseSearchCV.fit` times each candidate fold through `_fit_and_score`
(`mean_fit_time`, `mean_score_time` in `cv_results_`), but the **final** refit of
`best_estimator_` on the whole dataset is called directly, untimed. The wanted
quantity is simply not recorded anywhere. The fix is additive: time the final
`fit` and store the elapsed seconds as `self.refit_time_`.

## 2. Baseline's fix — and where it stopped

[Baseline](../verified500_analysis/scikit-learn__scikit-learn-11310/_materials/baseline.patch)
made the correct, minimal change in the module the issue names —
`sklearn/model_selection/_search.py` — wrapping the final `best_estimator_.fit(...)`
in a `time.time()` interval and documenting the attribute on both `GridSearchCV`
and `RandomizedSearchCV`. This is **logically identical to
[gold](../verified500_analysis/scikit-learn__scikit-learn-11310/_materials/gold.patch)**
(gold uses two timestamps instead of one subtraction; same behavior, same files).

Baseline was not careless — its notes show a deliberate scoping decision:

> *"Considered timing with a helper in `_validation.py`, but rejected that as
> unnecessary because the missing behavior is localized to `BaseSearchCV.fit`."*
> — [`reports/baseline_notes.md`](../results/verified036-codex-wsl-ubuntu-260615212520/scikit-learn__scikit-learn-11310/reports/baseline_notes.md#L34)

That reasoning is right for the *modern* base class. What it overlooks is that
the same feature has a **second public home**: the deprecated module
`sklearn/grid_search.py` keeps its own `BaseSearchCV._fit` with an independent
final-refit branch and its own `GridSearchCV` / `RandomizedSearchCV`. While that
module remains importable, it documents and implements the same final-refit
concept yet exposes no `refit_time_`. Baseline (and gold, and the official test)
left it unrepaired.

## 3. How FVK formally captured the gap

FVK started from intent, not the symptom. The intent spec lifts the issue's
"grid/random search" wording into a general requirement over the refit feature:

> **Required Behavior 1–2:** *fitting should expose a public attribute named
> `refit_time_` … the elapsed wall-clock time, in seconds, for the final
> full-data refit of the best model after grid or randomized search.*
> — [`fvk/INTENT_SPEC.md`](../results/verified036-codex-wsl-ubuntu-260615212520/scikit-learn__scikit-learn-11310/fvk/INTENT_SPEC.md#L9)

The evidence ledger pins that intent to a concrete code fact found by **source
audit** — the deprecated duplicate — rather than to the reported test:

> **E7 (source docs):** *Deprecated `repo/sklearn/grid_search.py` still documents
> `refit : boolean ... Refit the best estimator with the entire dataset.`* → *The
> deprecated public duplicate has the same observable final-refit concept while
> it remains present.* (Status: *Produced Finding F2 and V2 patch.*)
> — [`fvk/PUBLIC_EVIDENCE_LEDGER.md`](../results/verified036-codex-wsl-ubuntu-260615212520/scikit-learn__scikit-learn-11310/fvk/PUBLIC_EVIDENCE_LEDGER.md#L13)

Which is discharged into a formal obligation that names *both* implementations:

> **PO4 — Both public search implementations are covered.** *The refactored
> `sklearn.model_selection` search classes and the deprecated `sklearn.grid_search`
> duplicate both satisfy PO1 and PO2 while they remain present in the source tree.*
> — [`fvk/PROOF_OBLIGATIONS.md`](../results/verified036-codex-wsl-ubuntu-260615212520/scikit-learn__scikit-learn-11310/fvk/PROOF_OBLIGATIONS.md#L33)

This is the crux of FVK's value: **the second site was located by reasoning, not
observation.** The issue says "refit timing for grid/random search"; FVK turns
that into an invariant over *every* public search implementation, and the code
audit (E7) shows `sklearn.grid_search` is a second such implementation that the
modern fix never touches.

## 4. From formal output to the fix

The FVK arm's repair is iterative, and the artifacts record the exact step where
the formalism changed the patch.

- **V1** fixed `sklearn/model_selection/_search.py` only — identical to what
  baseline shipped. The completeness audit confirmed it satisfies the core
  intent (F1) but raised a finding against the duplicate:

  > **F2 — V1 missed the deprecated duplicate search implementation.** *Observed
  > in V1: the deprecated duplicate `BaseSearchCV._fit` refit branch fit the best
  > estimator and assigned `best_estimator_`, but did not record `refit_time_`.
  > … Resolution: V2 imports `time`, times the duplicate final `best_estimator.fit`
  > call, stores `self.refit_time_`, and documents the attribute in both
  > deprecated search class docstrings.*
  > — [`fvk/FINDINGS.md`](../results/verified036-codex-wsl-ubuntu-260615212520/scikit-learn__scikit-learn-11310/fvk/FINDINGS.md#L27)

- The iteration guidance turned the finding into the instruction for the next
  revision:

  > *"V2 addresses the only source-level issue surfaced by the FVK audit: the
  > deprecated `sklearn.grid_search` duplicate now records and documents
  > `refit_time_` consistently with `sklearn.model_selection`."*
  > — [`fvk/ITERATION_GUIDANCE.md`](../results/verified036-codex-wsl-ubuntu-260615212520/scikit-learn__scikit-learn-11310/fvk/ITERATION_GUIDANCE.md#L7)

- The decision log records the resulting change and its provenance:

  > *"FVK finding F2 identified a duplicate public final-refit path in deprecated
  > `sklearn.grid_search`. … PO4 requires both public search implementations to
  > satisfy the same refit-time obligation while both exist in the source tree.
  > The V2 patch imports `time`, starts the timer immediately before the
  > deprecated duplicate `best_estimator.fit(...)`, stores `self.refit_time_` …"*
  > — [`reports/fvk_notes.md`](../results/verified036-codex-wsl-ubuntu-260615212520/scikit-learn__scikit-learn-11310/reports/fvk_notes.md#L18)

The causal chain is fully on the record:

```
INTENT 1-2  ->  E7 (code audit: grid_search.py still implements the same refit)
            ->  PO4 (obligation: both public implementations must be covered)
            ->  F2  (V1 audit: deprecated duplicate still lacks refit_time_)
            ->  ITERATION_GUIDANCE / fvk_notes  ->  V2 patch (grid_search.py)
```

The `V1 -> V2` transition was driven by the formal finding **F2 / PO4**, **not**
by a new failing test — the official `test_search_cv_timing` only exercises
`sklearn.model_selection`, so no test for the deprecated module exists anywhere
in the suite. The [FVK patch](../verified500_analysis/scikit-learn__scikit-learn-11310/_materials/fvk.patch)
is exactly baseline's `_search.py` change **plus** the same timing/doc change
applied to `sklearn/grid_search.py`'s `BaseSearchCV._fit` and both deprecated
search classes.

## 5. Verification

This case is **source-and-artifact reviewed, not executed.** Although the
instance is curated (gold patch and tests available), there is **no
`enhanced_tests/_proof/` directory** for it, so there is no harness RED/GREEN
table, and the FVK artifacts explicitly state that no demonstration was run:

> *"the benchmark prohibits running tests, Python, or K tooling, so I emitted the
> exact `kompile`, `kast`, and `kprove` commands in the artifacts but did not
> execute them. No test files were modified."*
> — [`reports/fvk_notes.md`](../results/verified036-codex-wsl-ubuntu-260615212520/scikit-learn__scikit-learn-11310/reports/fvk_notes.md#L42)

What *is* verifiable by inspection:

- **Patch delta confirms the story.** `diff` of the two solution patches shows
  the FVK arm adds a complete new hunk for `sklearn/grid_search.py` (import
  `time`, time the duplicate `best_estimator.fit`, store `self.refit_time_`, two
  docstring additions) on top of an otherwise byte-for-byte-equivalent `_search.py`
  change ([`_materials/patches.diff`](../verified500_analysis/scikit-learn__scikit-learn-11310/_materials/patches.diff#L4)).
  Files only in fvk: `['sklearn/grid_search.py']`.
- **Gold comparison.** The human
  [gold patch](../verified500_analysis/scikit-learn__scikit-learn-11310/_materials/gold.patch)
  touches only `sklearn/model_selection/_search.py`; it never adds `refit_time_`
  to the deprecated module. FVK's extra fix goes beyond the human oracle.
- **Harness coverage is genuinely blind to the residual.** The only
  `FAIL_TO_PASS` test is
  `sklearn/model_selection/tests/test_search.py::test_search_cv_timing`
  ([`_materials/tests.json`](../verified500_analysis/scikit-learn__scikit-learn-11310/_materials/tests.json#L3)),
  which constructs a `sklearn.model_selection.GridSearchCV` only
  ([`_materials/gold_test.patch`](../verified500_analysis/scikit-learn__scikit-learn-11310/_materials/gold_test.patch#L16)).
  Nothing in the suite imports `sklearn.grid_search` and checks `refit_time_`, so
  the baseline gap is undetectable by the official evaluation — consistent with
  both arms being marked resolved.

## 6. Boundaries & honesty

- **Severity: Low.** The residual defect is a missing additive attribute on a
  **deprecated** module (`sklearn.grid_search`). Code that still imports it is
  itself on a deprecation path, so the trigger breadth is narrow and the impact
  magnitude is small. The value demonstrated here is **detection power and
  completeness** — auditing every public implementation of a feature — not impact
  magnitude. Severity is carried over unchanged from the prior rating.
- **Proof status: constructed, not machine-checked.** The K artifacts
  ([`fvk/mini-python-refit.k`](../results/verified036-codex-wsl-ubuntu-260615212520/scikit-learn__scikit-learn-11310/fvk/mini-python-refit.k),
  [`fvk/searchcv-refit-spec.k`](../results/verified036-codex-wsl-ubuntu-260615212520/scikit-learn__scikit-learn-11310/fvk/searchcv-refit-spec.k))
  and the `kompile`/`kast`/`kprove` commands were *written but never run* — the
  FVK artifacts say so explicitly
  ([`fvk/PROOF.md`](../results/verified036-codex-wsl-ubuntu-260615212520/scikit-learn__scikit-learn-11310/fvk/PROOF.md#L3),
  [finding F4](../results/verified036-codex-wsl-ubuntu-260615212520/scikit-learn__scikit-learn-11310/fvk/FINDINGS.md#L64)).
  We therefore claim **proof-structured reasoning** (a formal spec with obligations
  PO1–PO6 discharged by construction), **not a machine-checked proof**.
- **No harness verification of this instance.** Even though the instance is
  curated, no `enhanced_tests/_proof/` reports were produced, so the "Resolved"
  column above reflects the *official SWE-bench evaluation* (issue-level) and
  the residual-bug claim rests on **source review of the patch delta and the
  test suite**, not on an independent RED→GREEN run we executed.
- **Attribution.** The `V1 -> V2` iteration is documented across `FINDINGS.md`,
  `ITERATION_GUIDANCE.md`, and `fvk_notes.md`; the full ordering can be
  timestamped from
  [`transcripts/fvk.jsonl.gz`](../results/verified036-codex-wsl-ubuntu-260615212520/scikit-learn__scikit-learn-11310/transcripts/fvk.jsonl.gz)
  if a reviewer wants the raw trace.

## Artifact map

| Claim | Source |
|---|---|
| Issue text, use case | [`_materials/problem_statement.md`](../verified500_analysis/scikit-learn__scikit-learn-11310/_materials/problem_statement.md#L20) |
| Baseline patch | [`_materials/baseline.patch`](../verified500_analysis/scikit-learn__scikit-learn-11310/_materials/baseline.patch) |
| Baseline scoping decision | [`reports/baseline_notes.md`](../results/verified036-codex-wsl-ubuntu-260615212520/scikit-learn__scikit-learn-11310/reports/baseline_notes.md#L34) |
| FVK patch | [`_materials/fvk.patch`](../verified500_analysis/scikit-learn__scikit-learn-11310/_materials/fvk.patch) |
| Gold patch | [`_materials/gold.patch`](../verified500_analysis/scikit-learn__scikit-learn-11310/_materials/gold.patch) |
| Patch delta (fvk-only file) | [`_materials/patches.diff`](../verified500_analysis/scikit-learn__scikit-learn-11310/_materials/patches.diff#L4) |
| Intent (refit_time_ requirement) | [`fvk/INTENT_SPEC.md#L9`](../results/verified036-codex-wsl-ubuntu-260615212520/scikit-learn__scikit-learn-11310/fvk/INTENT_SPEC.md#L9) |
| Evidence E7 (deprecated duplicate) | [`fvk/PUBLIC_EVIDENCE_LEDGER.md#L13`](../results/verified036-codex-wsl-ubuntu-260615212520/scikit-learn__scikit-learn-11310/fvk/PUBLIC_EVIDENCE_LEDGER.md#L13) |
| Obligation PO4 (both implementations) | [`fvk/PROOF_OBLIGATIONS.md#L33`](../results/verified036-codex-wsl-ubuntu-260615212520/scikit-learn__scikit-learn-11310/fvk/PROOF_OBLIGATIONS.md#L33) |
| Finding F2 (V1 missed duplicate) | [`fvk/FINDINGS.md#L27`](../results/verified036-codex-wsl-ubuntu-260615212520/scikit-learn__scikit-learn-11310/fvk/FINDINGS.md#L27) |
| Honesty note F4 | [`fvk/FINDINGS.md#L64`](../results/verified036-codex-wsl-ubuntu-260615212520/scikit-learn__scikit-learn-11310/fvk/FINDINGS.md#L64) |
| Iteration instruction (V1→V2) | [`fvk/ITERATION_GUIDANCE.md#L7`](../results/verified036-codex-wsl-ubuntu-260615212520/scikit-learn__scikit-learn-11310/fvk/ITERATION_GUIDANCE.md#L7) |
| Decision trace (grid_search patch) | [`reports/fvk_notes.md#L18`](../results/verified036-codex-wsl-ubuntu-260615212520/scikit-learn__scikit-learn-11310/reports/fvk_notes.md#L18) |
| Did-not-execute note | [`reports/fvk_notes.md#L42`](../results/verified036-codex-wsl-ubuntu-260615212520/scikit-learn__scikit-learn-11310/reports/fvk_notes.md#L42) |
| Constructed proof status | [`fvk/PROOF.md#L3`](../results/verified036-codex-wsl-ubuntu-260615212520/scikit-learn__scikit-learn-11310/fvk/PROOF.md#L3) |
| Constructed K core | [`fvk/mini-python-refit.k`](../results/verified036-codex-wsl-ubuntu-260615212520/scikit-learn__scikit-learn-11310/fvk/mini-python-refit.k), [`fvk/searchcv-refit-spec.k`](../results/verified036-codex-wsl-ubuntu-260615212520/scikit-learn__scikit-learn-11310/fvk/searchcv-refit-spec.k) |
| Official test scope | [`_materials/tests.json#L3`](../verified500_analysis/scikit-learn__scikit-learn-11310/_materials/tests.json#L3), [`_materials/gold_test.patch#L16`](../verified500_analysis/scikit-learn__scikit-learn-11310/_materials/gold_test.patch#L16) |
| Raw model traces | [`transcripts/fvk.jsonl.gz`](../results/verified036-codex-wsl-ubuntu-260615212520/scikit-learn__scikit-learn-11310/transcripts/fvk.jsonl.gz) |

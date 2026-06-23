# scikit-learn__scikit-learn-14496

## Summary

**Severity:** High — baseline silently truncates fractional OPTICS sample counts instead of rounding them, so the algorithm runs to completion but computes neighbor and cluster-size thresholds off by one across every fractional `min_samples` / `min_cluster_size` input, producing wrong cluster results with no error.

Both arms passed the official SWE-bench evaluation for issue #14496 with **different** patches: baseline removes the float type with `max(2, int(min_samples * n_samples))` (truncation), while FVK uses the issue's documented form `int(round(max(2, min_samples * n_samples)))` (rounding). The defect is silent and broad — it changes the integer threshold fed to `NearestNeighbors` and `_xi_cluster` for a continuous range of in-domain fractions — and FVK located the mismatch by **lifting the docstring's "rounded to be at least 2" into a formal post-condition and auditing the conversion against it**, not by running a test.

| Arm | Fractional conversion (`0.26 * 10`) | Matches documented "rounded" count (`3`)? |
|---|---|---|
| baseline | `max(2, int(0.26*10))` = **2** | no |
| gold (human oracle) | rounded integer count | yes |
| **fvk** | `int(round(max(2, 0.26*10)))` = **3** | **yes** |

## 1. The issue and the real defect

The task ([`prompts/fvk.md`](../results/verified037-codex-wsl-ubuntu-260615221107/scikit-learn__scikit-learn-14496/prompts/fvk.md#L2)) is the scikit-learn OPTICS issue: `OPTICS` and `cluster_optics_xi` accept a fractional `min_samples` (a fraction of the sample count), but the scaled value was left as a float and passed to `NearestNeighbors(n_neighbors=...)`, which requires an integer and raises a `TypeError`. The issue's own evidence ledger captures the reported symptom and the intended fix shape:

> **IE2 (problem):** `min_samples = max(2, min_samples * n_samples)  # Still a float`
> — [`fvk/SPEC.md`](../results/verified037-codex-wsl-ubuntu-260615221107/scikit-learn__scikit-learn-14496/fvk/SPEC.md#L41)

> **IE3 (problem):** `NearestNeighbours class with a float it raises`
> — [`fvk/SPEC.md`](../results/verified037-codex-wsl-ubuntu-260615221107/scikit-learn__scikit-learn-14496/fvk/SPEC.md#L42)

The user-facing observable that is wrong is the **integer threshold** itself: the existing docstring already promises `min_samples` is interpreted as "a fraction of the number of samples (rounded to be at least 2)" ([`fvk/SPEC.md`](../results/verified037-codex-wsl-ubuntu-260615221107/scikit-learn__scikit-learn-14496/fvk/SPEC.md#L47)). Removing the float without rounding satisfies the type but not the documented count.

## 2. Baseline's fix — and where it stopped

[Baseline](../results/verified037-codex-wsl-ubuntu-260615221107/scikit-learn__scikit-learn-14496/solutions/solution_baseline.patch) made the float a count by wrapping the scaled value in `int(...)`, at all three normalization sites:

```python
if min_samples <= 1:
    min_samples = max(2, int(min_samples * n_samples))
```

It also updated the `compute_optics_graph` docstring to document the fractional form. Baseline was not careless — its notes show it **consciously rejected rounding**:

> *"I considered using nearest-integer rounding or `ceil`, but rejected those because the existing code only needed to remove the float type before count usage, and the public discussion explicitly suggested direct integer conversion rather than compatibility-oriented `round(...)` wrapping."*
> — [`reports/baseline_notes.md`](../results/verified037-codex-wsl-ubuntu-260615221107/scikit-learn__scikit-learn-14496/reports/baseline_notes.md#L31)

That reasoning fixes the `TypeError` but leaves one obligation unmet: the **value** of the integer. `int(...)` truncates toward zero, so `0.26 * 10 = 2.6` becomes `2`, whereas the docstring's "rounded" semantics require `3`. Baseline proved the value is *an* integer; it did not prove it is the *intended* integer.

## 3. How FVK formally captured the gap

FVK started from intent, not from the symptom. The decisive intent item demands a *rounded, lower-bounded* count, not merely an integer:

> **Intent 3:** *"The converted count is rounded and bounded below by 2."*
> — [`fvk/SPEC.md`](../results/verified037-codex-wsl-ubuntu-260615221107/scikit-learn__scikit-learn-14496/fvk/SPEC.md#L28)

That intent is pinned to a concrete code fact taken from the issue and docstring — **not** from the reported `TypeError` test, which only proves the type:

> **IE4 (problem):** `int(round(max(2, min_samples * n_samples)))` and `round to get the closest integer` → *"The fractional conversion should use rounding, not truncation."*
> — [`fvk/SPEC.md`](../results/verified037-codex-wsl-ubuntu-260615221107/scikit-learn__scikit-learn-14496/fvk/SPEC.md#L43)

Which is discharged into an exact-value proof obligation over the conversion:

> **PO2:** *In `compute_optics_graph`, if validated `min_samples <= 1`, the normalized count is exactly `int(round(max(2, min_samples * n_samples)))`.*
> — [`fvk/PROOF_OBLIGATIONS.md`](../results/verified037-codex-wsl-ubuntu-260615221107/scikit-learn__scikit-learn-14496/fvk/PROOF_OBLIGATIONS.md#L9)

This is the crux: FVK's obligation is about the *exact integer*, so the baseline's `max(2, int(...))` is detectable as a violation by **reasoning** — the conversion does not equal the obligation's expression for any non-integral product — rather than by observing a failing run.

## 4. From formal output to the fix

The completeness audit of the V1 (baseline-shaped) conversion against PO2 raised a finding with a concrete counterexample:

> **F1: V1 Truncated Fractional Counts Instead of Rounding.** Observed `max(2, int(0.26 * 10)) == 2`; expected `int(round(max(2, 0.26 * 10))) == 3`. *Classification: code bug in V1.*
> — [`fvk/FINDINGS.md`](../results/verified037-codex-wsl-ubuntu-260615221107/scikit-learn__scikit-learn-14496/fvk/FINDINGS.md#L5)

The same defect class extends to the Xi extraction path:

> **F3: Xi Extraction Needed the Same Fractional Count Semantics.** *V1 converted them but used truncation … fixed in V2.*
> — [`fvk/FINDINGS.md`](../results/verified037-codex-wsl-ubuntu-260615221107/scikit-learn__scikit-learn-14496/fvk/FINDINGS.md#L45)

The iteration guidance turned the finding into a direct instruction:

> *"V1 should not stand unchanged. Finding F1 showed that V1 truncated fractional sample counts … V2 changes only the three fractional conversions … to `int(round(max(2, size * n_samples)))`."*
> — [`fvk/ITERATION_GUIDANCE.md`](../results/verified037-codex-wsl-ubuntu-260615221107/scikit-learn__scikit-learn-14496/fvk/ITERATION_GUIDANCE.md#L7)

And the decision log records the provenance from finding to obligation to code:

> *"Changed V1 truncation to rounded integer conversion … F1 shows a concrete V1 mismatch (`0.26 * 10` truncates to 2 but rounds to 3) … PO2 and PO4 require the rounded expression for both `compute_optics_graph` and `cluster_optics_xi`."*
> — [`reports/fvk_notes.md`](../results/verified037-codex-wsl-ubuntu-260615221107/scikit-learn__scikit-learn-14496/reports/fvk_notes.md#L5)

The causal chain is fully on the record:

```
SPEC Intent-3  ->  IE4 (issue: conversion must round, not truncate)
              ->  PO2 / PO4 (obligation: count is exactly int(round(max(2, scaled))))
              ->  F1 / F3 (audit: V1 truncation yields 2 where 3 is required)
              ->  ITERATION_GUIDANCE / fvk_notes  ->  V2 patch
```

The resulting [FVK patch](../results/verified037-codex-wsl-ubuntu-260615221107/scikit-learn__scikit-learn-14496/solutions/solution_fvk.patch) replaces all three conversions with the rounded form:

```python
if min_samples <= 1:
    min_samples = int(round(max(2, min_samples * n_samples)))
```

The `V1 -> V2` transition was driven by the formal finding (F1/PO2), **not** by a new failing test — the run had no test results and no execution environment ([`prompts/fvk.md`](../results/verified037-codex-wsl-ubuntu-260615221107/scikit-learn__scikit-learn-14496/prompts/fvk.md#L26)), so the rounding gap was reached purely from the docstring-derived obligation.

## 5. Verification

This case is **non-curated (Tier 3): source-and-artifact reviewed; not executed.** There is no curated `verified500_analysis/` directory, no gold-patch file, and no harness `_proof/*.report.json` reports for this instance, so no RED/GREEN harness table can be shown and none is claimed.

What was inspected:

- The two patches were diffed directly: baseline uses `max(2, int(min_samples * n_samples))` at all three sites ([`solution_baseline.patch`](../results/verified037-codex-wsl-ubuntu-260615221107/scikit-learn__scikit-learn-14496/solutions/solution_baseline.patch)); FVK uses `int(round(max(2, min_samples * n_samples)))` ([`solution_fvk.patch`](../results/verified037-codex-wsl-ubuntu-260615221107/scikit-learn__scikit-learn-14496/solutions/solution_fvk.patch)). The delta is exactly truncation vs rounding.
- The hand-computed counterexample in [`fvk/FINDINGS.md`](../results/verified037-codex-wsl-ubuntu-260615221107/scikit-learn__scikit-learn-14496/fvk/FINDINGS.md#L13) (`0.26 * 10`: baseline → 2, FVK → 3) was checked against the docstring's documented "rounded" semantics ([`fvk/SPEC.md`](../results/verified037-codex-wsl-ubuntu-260615221107/scikit-learn__scikit-learn-14496/fvk/SPEC.md#L47)).
- **Gold comparison (prose only, no gold file available):** the FVK form `int(round(max(2, ...)))` is identical to the expression the issue itself proposes (IE4), which is the upstream-accepted shape; the baseline form diverges from it by dropping `round`. We therefore judge FVK's value as documented-semantics-faithful and baseline's as a residual off-by-rounding error, but this comparison rests on the issue text and patch deltas, not on an executed gold oracle.

No behavioral demonstration table is reproduced here because the old report carried only prose, not an executed variants→output table, and the run had no execution environment.

## 6. Boundaries & honesty

- **Severity: High.** The trigger breadth is wide: every fractional `min_samples` (and `min_cluster_size`) whose product with `n_samples` is non-integral and rounds up — a continuous band of ordinary in-domain inputs across `compute_optics_graph` and `cluster_optics_xi` — gets a threshold one lower than documented. The algorithm still runs and returns labels, so the error is **silent**: clusters are computed with the wrong neighbor / cluster-size threshold and no exception is raised ([severity rationale carried from the source report's "silent analytical result error"]). That combination — broad trigger, no signal, wrong analytical output — is the High rubric.
- **Proof status: constructed, not machine-checked.** The K artifacts ([`fvk/mini-optics-size.k`](../results/verified037-codex-wsl-ubuntu-260615221107/scikit-learn__scikit-learn-14496/fvk/mini-optics-size.k), [`fvk/optics-size-spec.k`](../results/verified037-codex-wsl-ubuntu-260615221107/scikit-learn__scikit-learn-14496/fvk/optics-size-spec.k)) and the `kompile`/`kast`/`kprove` commands were **written but never run** — the artifacts say so explicitly ([`fvk/PROOF.md`](../results/verified037-codex-wsl-ubuntu-260615221107/scikit-learn__scikit-learn-14496/fvk/PROOF.md#L3)). The model also abstracts Python float and tie-breaking semantics as an acknowledged proof-capability boundary (F4/PO7). We therefore claim **proof-structured reasoning**, not a machine-checked proof.
- **Attribution.** This is a non-curated case: there is no harness RED→GREEN confirmation, so the conclusion that baseline is wrong rests on the static delta plus the issue/docstring evidence, not on an independent executed oracle. The `V1 -> V2` ordering is documented across `FINDINGS.md`, `ITERATION_GUIDANCE.md`, and `fvk_notes.md`; the raw trace can be timestamped from [`transcripts/fvk.jsonl.gz`](../results/verified037-codex-wsl-ubuntu-260615221107/scikit-learn__scikit-learn-14496/transcripts/fvk.jsonl.gz) if a reviewer wants it.

## Artifact map

| Claim | Source |
|---|---|
| Issue text, repro (`TypeError` on float `n_neighbors`) | [`fvk/SPEC.md#L41`](../results/verified037-codex-wsl-ubuntu-260615221107/scikit-learn__scikit-learn-14496/fvk/SPEC.md#L41), [`fvk/SPEC.md#L42`](../results/verified037-codex-wsl-ubuntu-260615221107/scikit-learn__scikit-learn-14496/fvk/SPEC.md#L42) |
| Problem-statement / task framing | [`prompts/fvk.md#L2`](../results/verified037-codex-wsl-ubuntu-260615221107/scikit-learn__scikit-learn-14496/prompts/fvk.md#L2) |
| No execution environment / no test results | [`prompts/fvk.md#L26`](../results/verified037-codex-wsl-ubuntu-260615221107/scikit-learn__scikit-learn-14496/prompts/fvk.md#L26) |
| Baseline patch (truncation) | [`solutions/solution_baseline.patch`](../results/verified037-codex-wsl-ubuntu-260615221107/scikit-learn__scikit-learn-14496/solutions/solution_baseline.patch) |
| Baseline rejected rounding | [`reports/baseline_notes.md#L31`](../results/verified037-codex-wsl-ubuntu-260615221107/scikit-learn__scikit-learn-14496/reports/baseline_notes.md#L31) |
| FVK patch (rounding) | [`solutions/solution_fvk.patch`](../results/verified037-codex-wsl-ubuntu-260615221107/scikit-learn__scikit-learn-14496/solutions/solution_fvk.patch) |
| Intent: count is rounded, bounded ≥ 2 | [`fvk/SPEC.md#L28`](../results/verified037-codex-wsl-ubuntu-260615221107/scikit-learn__scikit-learn-14496/fvk/SPEC.md#L28) |
| Docstring "rounded to be at least 2" (IE8) | [`fvk/SPEC.md#L47`](../results/verified037-codex-wsl-ubuntu-260615221107/scikit-learn__scikit-learn-14496/fvk/SPEC.md#L47) |
| Evidence IE4 (round, not truncate) | [`fvk/SPEC.md#L43`](../results/verified037-codex-wsl-ubuntu-260615221107/scikit-learn__scikit-learn-14496/fvk/SPEC.md#L43) |
| Obligation PO2 (exact rounded count) | [`fvk/PROOF_OBLIGATIONS.md#L9`](../results/verified037-codex-wsl-ubuntu-260615221107/scikit-learn__scikit-learn-14496/fvk/PROOF_OBLIGATIONS.md#L9) |
| Obligation PO4 (Xi same conversion) | [`fvk/PROOF_OBLIGATIONS.md#L11`](../results/verified037-codex-wsl-ubuntu-260615221107/scikit-learn__scikit-learn-14496/fvk/PROOF_OBLIGATIONS.md#L11) |
| Finding F1 (counterexample 0.26·10) | [`fvk/FINDINGS.md#L5`](../results/verified037-codex-wsl-ubuntu-260615221107/scikit-learn__scikit-learn-14496/fvk/FINDINGS.md#L5), [`fvk/FINDINGS.md#L13`](../results/verified037-codex-wsl-ubuntu-260615221107/scikit-learn__scikit-learn-14496/fvk/FINDINGS.md#L13) |
| Finding F3 (Xi path) | [`fvk/FINDINGS.md#L45`](../results/verified037-codex-wsl-ubuntu-260615221107/scikit-learn__scikit-learn-14496/fvk/FINDINGS.md#L45) |
| Iteration instruction (V1→V2) | [`fvk/ITERATION_GUIDANCE.md#L7`](../results/verified037-codex-wsl-ubuntu-260615221107/scikit-learn__scikit-learn-14496/fvk/ITERATION_GUIDANCE.md#L7) |
| Decision trace (round, PO2/PO4) | [`reports/fvk_notes.md#L5`](../results/verified037-codex-wsl-ubuntu-260615221107/scikit-learn__scikit-learn-14496/reports/fvk_notes.md#L5) |
| Constructed K core | [`fvk/mini-optics-size.k`](../results/verified037-codex-wsl-ubuntu-260615221107/scikit-learn__scikit-learn-14496/fvk/mini-optics-size.k), [`fvk/optics-size-spec.k`](../results/verified037-codex-wsl-ubuntu-260615221107/scikit-learn__scikit-learn-14496/fvk/optics-size-spec.k) |
| Proof not machine-checked | [`fvk/PROOF.md#L3`](../results/verified037-codex-wsl-ubuntu-260615221107/scikit-learn__scikit-learn-14496/fvk/PROOF.md#L3) |
| Raw model traces | [`transcripts/fvk.jsonl.gz`](../results/verified037-codex-wsl-ubuntu-260615221107/scikit-learn__scikit-learn-14496/transcripts/fvk.jsonl.gz) |

# scikit-learn__scikit-learn-26323

## Summary

**Severity:** Low — once `ColumnTransformer.set_output` is taught to forward
configuration to an estimator-valued `remainder`, the shared helper
`_safe_set_output` can violate its own documented `transform=None` no-op for the
narrow class of children that define `transform` but not `set_output`; the
trigger is a single uncommon argument value on one newly-reached path, so the
blast radius is small.

Baseline and FVK both passed the official SWE-bench evaluation for this issue,
with **different** patches. The reported bug — `set_output` ignoring an
estimator `remainder` — is fixed identically by both arms in
`_column_transformer.py`. The FVK arm adds a **second** change to
`sklearn/utils/_set_output.py`: an early `if transform is None: return estimator`
guard that makes the helper's documented `None` no-op explicit before it checks
the child's capabilities. FVK reached that guard by auditing the no-op contract
of the helper it had just widened, not by observing a new test failure.

| Arm | `test_remainder_set_output` (FAIL_TO_PASS) | Resolved |
|---|---|---|
| baseline | [**resolved**](../results/verified038-codex-wsl-ubuntu-260615221107/scikit-learn__scikit-learn-26323/eval/baseline.report.json#L4) | yes |
| **fvk** | [**resolved**](../results/verified038-codex-wsl-ubuntu-260615221107/scikit-learn__scikit-learn-26323/eval/fvk.report.json#L4) | **yes** |

## 1. The issue and the real defect

The task is the *continue* form of SWE-bench issue
`scikit-learn__scikit-learn-26323`: *"`ColumnTransformer.set_output` ignores the
`remainder` if it's an estimator"* — calling `set_output(transform="pandas")`
*"sets the output to its sub-transformers but it ignores the transformer defined
in `remainder`"*
([`fvk/PUBLIC_EVIDENCE_LEDGER.md` E1/E2](../results/verified038-codex-wsl-ubuntu-260615221107/scikit-learn__scikit-learn-26323/fvk/PUBLIC_EVIDENCE_LEDGER.md#L7)).
The problem statement lives in the benchmark's `benchmark/PROBLEM.md`, supplied
to the model through the
[`fvk.md` prompt](../results/verified038-codex-wsl-ubuntu-260615221107/scikit-learn__scikit-learn-26323/prompts/fvk.md#L12)
(that file is not redistributed in the run directory; no public GitHub URL is
recorded in the artifacts).

`ColumnTransformer.set_output` propagates the requested output container to its
child transformers, but it only walked `transformers` (and, post-fit,
`transformers_`). An estimator passed via `remainder` is, semantically, a child
transformer for every unselected column — yet it was never configured. Because
`fit_transform` clones the *unfitted* `self.remainder`, the clone produced
default ndarray output while explicit children produced pandas, so `_hstack`
mixed containers and lost the pandas dtype for the remainder result
([`reports/baseline_notes.md`](../results/verified038-codex-wsl-ubuntu-260615221107/scikit-learn__scikit-learn-26323/reports/baseline_notes.md#L9)).

## 2. Baseline's fix — and where it stopped

[Baseline](../results/verified038-codex-wsl-ubuntu-260615221107/scikit-learn__scikit-learn-26323/solutions/solution_baseline.patch#L20)
added the obvious propagation branch in `ColumnTransformer.set_output`:

```python
if self.remainder not in {"passthrough", "drop"}:
    _safe_set_output(self.remainder, transform=transform)
```

This is correct and minimal, and its reasoning is sound: baseline treated
`remainder` as following "the same output-configuration contract as explicitly
listed transformers because it is a nested transformer whenever it is an
estimator"
([`reports/baseline_notes.md`](../results/verified038-codex-wsl-ubuntu-260615221107/scikit-learn__scikit-learn-26323/reports/baseline_notes.md#L30)).
The branch also correctly skips the `"passthrough"`/`"drop"` sentinels.

What baseline did **not** do is re-examine the helper it now calls on a new kind
of argument. `set_output(transform=None)` is a documented no-op, and the new
branch forwards `transform` unconditionally — so when `transform is None`,
`_safe_set_output(self.remainder, transform=None)` runs. The unmet obligation is
exactly that the helper honor its `None` no-op for this newly-reachable child
([`fvk/PUBLIC_EVIDENCE_LEDGER.md` E8](../results/verified038-codex-wsl-ubuntu-260615221107/scikit-learn__scikit-learn-26323/fvk/PUBLIC_EVIDENCE_LEDGER.md#L14)).
Baseline stopped one step short: it widened the helper's reach without first
confirming the helper's no-op contract holds on the widened path.

## 3. How FVK formally captured the gap

FVK worked from an intent specification, not from the symptom. The decisive
intent item separates the *no-op* meaning of `transform=None` from the
propagation behavior:

> **Public Intent #6:** *`transform=None` means configuration is unchanged. It
> is a no-op for output configuration propagation.*
> — [`fvk/INTENT_SPEC.md`](../results/verified038-codex-wsl-ubuntu-260615221107/scikit-learn__scikit-learn-26323/fvk/INTENT_SPEC.md#L20)

The evidence ledger pins that intent to a concrete code fact found by source
audit — the helper's own docstring — and explicitly flags it as a V1 gap:

> **E8 (`repo/sklearn/utils/_set_output.py` docstring):** *"If `None`, this
> operation is a no-op."* → *`_safe_set_output(..., transform=None)` must not
> require child `set_output`.* … *V1 gap, fixed by V2.*
> — [`fvk/PUBLIC_EVIDENCE_LEDGER.md`](../results/verified038-codex-wsl-ubuntu-260615221107/scikit-learn__scikit-learn-26323/fvk/PUBLIC_EVIDENCE_LEDGER.md#L14)

Which is discharged into a formal obligation:

> **PO-4 — `transform=None` Is A No-Op.** *Calling
> `_safe_set_output(estimator, transform=None)` must leave configuration
> unchanged and must not require `estimator.set_output`.* … *V1 status: failed
> for estimators with `transform` but no `set_output`.*
> — [`fvk/PROOF_OBLIGATIONS.md`](../results/verified038-codex-wsl-ubuntu-260615221107/scikit-learn__scikit-learn-26323/fvk/PROOF_OBLIGATIONS.md#L38)

The crux of FVK's value here is that the no-op edge was located by **reasoning
about a contract**, not by a failing test. The reported issue is only about
propagating to `remainder`; FVK lifts the helper's documented `None` no-op into
an obligation and notices that V1's own propagation change is what makes that
obligation reachable for unconfigurable children — closing the loop the issue
opened.

## 4. From formal output to the fix

The FVK arm's repair is iterative: V1 fixed the reported propagation gap, and the
spec-driven audit of V1 surfaced the helper edge as a distinct finding.

- The completeness audit raised a finding tying the no-op edge to V1's own change:

  > **F-002: V1 Widened A Pre-Existing `transform=None` Helper Edge.** *Input:
  > `_safe_set_output(estimator_without_set_output_but_with_transform,
  > transform=None)`, now reachable through the new remainder propagation path.*
  > … *Resolution: V2 adds an early `if transform is None: return estimator` to
  > `_safe_set_output`.*
  > — [`fvk/FINDINGS.md`](../results/verified038-codex-wsl-ubuntu-260615221107/scikit-learn__scikit-learn-26323/fvk/FINDINGS.md#L20)

- The iteration guidance turned the finding into the instruction for V2:

  > *"F-002 and PO-4 justify the V2 helper change: once `ColumnTransformer` calls
  > `_safe_set_output` on `remainder`, the helper's documented `None` no-op must
  > be honored for that path as well."*
  > — [`fvk/ITERATION_GUIDANCE.md`](../results/verified038-codex-wsl-ubuntu-260615221107/scikit-learn__scikit-learn-26323/fvk/ITERATION_GUIDANCE.md#L15)

- The decision log records the resulting change and its provenance:

  > *"Added a V2 change in `repo/sklearn/utils/_set_output.py`. This is justified
  > by F-002 and PO-4. V1 made the helper reachable for estimator-valued
  > `remainder`, so the helper's documented `transform=None` no-op needed to be
  > explicit before checking whether the child has `set_output`."*
  > — [`reports/fvk_notes.md`](../results/verified038-codex-wsl-ubuntu-260615221107/scikit-learn__scikit-learn-26323/reports/fvk_notes.md#L12)

The causal chain is on the record:

```
INTENT #6  ->  E8 (docstring audit: transform=None is a documented no-op)
           ->  PO-4 (obligation: None must not require child set_output)
           ->  F-002 (V1 audit: remainder path can now reach an unconfigurable child)
           ->  ITERATION_GUIDANCE / fvk_notes  ->  V2 helper hunk
```

The resulting
[V2 patch](../results/verified038-codex-wsl-ubuntu-260615221107/scikit-learn__scikit-learn-26323/solutions/solution_fvk.patch#L34)
adds the guard at the top of `_safe_set_output`:

```python
if transform is None:
    return estimator
```

This makes the `None` no-op precede the original capability check (whose
`hasattr(...) or hasattr(...) and transform is not None` precedence had let the
`None` case fall through to the error path for `transform`-only estimators). F-003
records that the non-`None` error path is preserved, since the early return fires
only for `transform is None`
([`fvk/FINDINGS.md` F-003](../results/verified038-codex-wsl-ubuntu-260615221107/scikit-learn__scikit-learn-26323/fvk/FINDINGS.md#L33)).
The `V1 -> V2` transition was driven by the formal finding F-002/PO-4, **not** by
a new failing test — the audit explicitly notes no tests or code were run
([`fvk/FINDINGS.md`](../results/verified038-codex-wsl-ubuntu-260615221107/scikit-learn__scikit-learn-26323/fvk/FINDINGS.md#L3)).

## 5. Verification

This case is **non-curated** (no `verified500_analysis/`, no gold patch, no
harness RED/GREEN proof reports). Verification here is **source-and-artifact
review, not execution.**

- **Official evaluation.** Both arms are marked `resolved` against the hidden
  suite, with the issue's regression test `test_remainder_set_output` moving to
  PASS and all 178 `PASS_TO_PASS` tests holding
  ([baseline](../results/verified038-codex-wsl-ubuntu-260615221107/scikit-learn__scikit-learn-26323/eval/baseline.report.json#L8),
  [fvk](../results/verified038-codex-wsl-ubuntu-260615221107/scikit-learn__scikit-learn-26323/eval/fvk.report.json#L8)).
  That evaluation does **not** exercise the `transform=None`-on-remainder edge,
  so it neither confirms nor refutes the residual defect; it only shows the V2
  helper guard introduced no regression.
- **What was inspected.** The two solution patches were diffed
  ([baseline](../results/verified038-codex-wsl-ubuntu-260615221107/scikit-learn__scikit-learn-26323/solutions/solution_baseline.patch),
  [fvk](../results/verified038-codex-wsl-ubuntu-260615221107/scikit-learn__scikit-learn-26323/solutions/solution_fvk.patch#L34))
  and confirmed to differ in exactly the `_set_output.py` guard. The helper's
  documented no-op (E8), the obligation that encodes it (PO-4), and the finding
  that ties it to V1's reach (F-002) were read against the patch hunk. No
  behavioral demo was executed in this environment.

## 6. Boundaries & honesty

- **Severity: Low.** The residual defect triggers only on a single argument value
  (`transform=None`) reaching one newly-configured child (`remainder`) of one
  narrow shape (defines `transform`, lacks `set_output`). That trigger breadth is
  small; the value demonstrated is the **completeness audit** — FVK re-checked the
  contract of the helper it widened — not the magnitude of any impact. Severity is
  carried forward unchanged from the prior assessment.
- **Proof status: constructed, not machine-checked.** The K artifacts
  ([`mini-column-transformer.k`](../results/verified038-codex-wsl-ubuntu-260615221107/scikit-learn__scikit-learn-26323/fvk/mini-column-transformer.k),
  [`column-transformer-set-output-spec.k`](../results/verified038-codex-wsl-ubuntu-260615221107/scikit-learn__scikit-learn-26323/fvk/column-transformer-set-output-spec.k))
  and the `kompile`/`kprove` commands were **written but never run** — the
  artifacts say so explicitly
  ([`fvk/PROOF.md`](../results/verified038-codex-wsl-ubuntu-260615221107/scikit-learn__scikit-learn-26323/fvk/PROOF.md#L3)).
  We therefore claim **proof-structured reasoning** (a spec with obligations
  discharged by construction), **not a machine-checked proof**.
- **Attribution.** The reported-bug fix is identical across arms, so the harness
  `resolved` verdict cannot distinguish them. The only FVK-specific change is the
  `_set_output.py` guard, and its justification is **reconstructed from the FVK
  artifacts** (F-002, PO-4, fvk_notes), not from an observed failing test — no
  test covers the `transform=None`-on-remainder edge in the available evidence.

## Artifact map

| Claim | Source |
|---|---|
| Issue text (E1/E2) | [`fvk/PUBLIC_EVIDENCE_LEDGER.md#L7`](../results/verified038-codex-wsl-ubuntu-260615221107/scikit-learn__scikit-learn-26323/fvk/PUBLIC_EVIDENCE_LEDGER.md#L7) |
| Problem statement supplied via prompt | [`prompts/fvk.md#L12`](../results/verified038-codex-wsl-ubuntu-260615221107/scikit-learn__scikit-learn-26323/prompts/fvk.md#L12) |
| Root cause (remainder clone loses pandas) | [`reports/baseline_notes.md#L9`](../results/verified038-codex-wsl-ubuntu-260615221107/scikit-learn__scikit-learn-26323/reports/baseline_notes.md#L9) |
| Baseline patch (remainder branch) | [`solutions/solution_baseline.patch#L20`](../results/verified038-codex-wsl-ubuntu-260615221107/scikit-learn__scikit-learn-26323/solutions/solution_baseline.patch#L20) |
| Baseline reasoning | [`reports/baseline_notes.md#L30`](../results/verified038-codex-wsl-ubuntu-260615221107/scikit-learn__scikit-learn-26323/reports/baseline_notes.md#L30) |
| Unmet obligation (E8 no-op) | [`fvk/PUBLIC_EVIDENCE_LEDGER.md#L14`](../results/verified038-codex-wsl-ubuntu-260615221107/scikit-learn__scikit-learn-26323/fvk/PUBLIC_EVIDENCE_LEDGER.md#L14) |
| Intent #6 (`transform=None` no-op) | [`fvk/INTENT_SPEC.md#L20`](../results/verified038-codex-wsl-ubuntu-260615221107/scikit-learn__scikit-learn-26323/fvk/INTENT_SPEC.md#L20) |
| Obligation PO-4 | [`fvk/PROOF_OBLIGATIONS.md#L38`](../results/verified038-codex-wsl-ubuntu-260615221107/scikit-learn__scikit-learn-26323/fvk/PROOF_OBLIGATIONS.md#L38) |
| Finding F-002 (V1 widened the edge) | [`fvk/FINDINGS.md#L20`](../results/verified038-codex-wsl-ubuntu-260615221107/scikit-learn__scikit-learn-26323/fvk/FINDINGS.md#L20) |
| Finding F-003 (non-`None` error preserved) | [`fvk/FINDINGS.md#L33`](../results/verified038-codex-wsl-ubuntu-260615221107/scikit-learn__scikit-learn-26323/fvk/FINDINGS.md#L33) |
| Iteration instruction (V1→V2) | [`fvk/ITERATION_GUIDANCE.md#L15`](../results/verified038-codex-wsl-ubuntu-260615221107/scikit-learn__scikit-learn-26323/fvk/ITERATION_GUIDANCE.md#L15) |
| Decision trace (V2 helper change) | [`reports/fvk_notes.md#L12`](../results/verified038-codex-wsl-ubuntu-260615221107/scikit-learn__scikit-learn-26323/reports/fvk_notes.md#L12) |
| FVK patch (helper guard) | [`solutions/solution_fvk.patch#L34`](../results/verified038-codex-wsl-ubuntu-260615221107/scikit-learn__scikit-learn-26323/solutions/solution_fvk.patch#L34) |
| Constructed K core | [`fvk/mini-column-transformer.k`](../results/verified038-codex-wsl-ubuntu-260615221107/scikit-learn__scikit-learn-26323/fvk/mini-column-transformer.k), [`fvk/column-transformer-set-output-spec.k`](../results/verified038-codex-wsl-ubuntu-260615221107/scikit-learn__scikit-learn-26323/fvk/column-transformer-set-output-spec.k) |
| Proof not machine-checked | [`fvk/PROOF.md#L3`](../results/verified038-codex-wsl-ubuntu-260615221107/scikit-learn__scikit-learn-26323/fvk/PROOF.md#L3) |
| No tests/code were run | [`fvk/FINDINGS.md#L3`](../results/verified038-codex-wsl-ubuntu-260615221107/scikit-learn__scikit-learn-26323/fvk/FINDINGS.md#L3) |
| Both arms resolved | [`eval/baseline.report.json#L4`](../results/verified038-codex-wsl-ubuntu-260615221107/scikit-learn__scikit-learn-26323/eval/baseline.report.json#L4), [`eval/fvk.report.json#L4`](../results/verified038-codex-wsl-ubuntu-260615221107/scikit-learn__scikit-learn-26323/eval/fvk.report.json#L4) |

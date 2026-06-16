# FVK Notes

Status: constructed, not machine-checked.

## Decision

V1 stands unchanged. The FVK audit did not justify any additional production
source edit.

## Trace from findings to decisions

F-001 identifies the original bug: `fit` recorded feature names from a
DataFrame, transformed local `X` to an internal array, and then used public
`score_samples`, which revalidated the array and emitted the invalid-feature-
names warning. PO-1 and PO-7 discharge the corrected behavior: V1 computes the
non-auto offset with private `_score_samples`, so the internal path cannot emit
that warning. Decision: keep the V1 `fit` call to `self._score_samples(X)`.

F-002 checks that V1 did not over-fix by suppressing public feature-name
warnings. PO-3 discharges this: public `score_samples` still calls
`_validate_data(..., reset=False)` before private scoring. Decision: keep the
public validation in `score_samples` unchanged.

F-003 identifies the sparse representation risk created by bypassing public
`score_samples`: `fit` may have CSC input while tree scoring expects CSR. PO-5
discharges this because V1 converts sparse inputs with `X.tocsr()` inside the
private helper. Decision: keep the sparse conversion in `_score_samples`.

F-004 audits compatibility. PO-6 shows public signatures and return shapes are
unchanged, with no in-repo subclass or override conflict. The residual external
subclass case is not enough to reject V1 because the public issue specifically
calls for an internal no-validation scoring path. Decision: no compatibility
patch is needed.

F-005 records the proof boundary: the K proof abstracts raw tree scoring and
percentile arithmetic. That limitation does not point to a source bug because
the issue concerns validation/warning control flow. Decision: do not refactor
the numerical scoring code.

## Artifacts written

Required artifacts:

- `fvk/SPEC.md`
- `fvk/FINDINGS.md`
- `fvk/PROOF_OBLIGATIONS.md`
- `fvk/PROOF.md`
- `fvk/ITERATION_GUIDANCE.md`

Additional FVK adequacy/formal-core artifacts:

- `fvk/INTENT_SPEC.md`
- `fvk/PUBLIC_EVIDENCE_LEDGER.md`
- `fvk/FORMAL_SPEC_ENGLISH.md`
- `fvk/SPEC_AUDIT.md`
- `fvk/PUBLIC_COMPATIBILITY_AUDIT.md`
- `fvk/mini-iforest.k`
- `fvk/iforest-fit-spec.k`

## Execution note

No tests, Python code, or K tooling were run, as required by the task. The
`kompile`, `kast`, and `kprove` commands are recorded in the FVK artifacts for
a future environment but were not executed here.

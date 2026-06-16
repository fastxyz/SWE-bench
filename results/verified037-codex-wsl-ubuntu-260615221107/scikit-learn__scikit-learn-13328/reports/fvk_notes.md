# FVK Notes

## Decision Summary

V1 stands unchanged. The FVK audit found that the existing V1 edit places dtype
coercion at the public `HuberRegressor.fit` validation boundary, which matches
the issue intent.

## Traceability

No additional production code edits were made after V1.

Reason: `fvk/FINDINGS.md` F-001 identifies the original source bug as boolean
`X` reaching unary minus in `_huber_loss_and_gradient`. The V1 source edit
discharges `fvk/PROOF_OBLIGATIONS.md` PO-001, PO-002, and PO-003 by making
`HuberRegressor.fit` call `check_X_y(..., dtype=FLOAT_DTYPES)`, which converts
boolean `X` to floating point before the optimizer/loss path.

The choice to keep `FLOAT_DTYPES` instead of forcing `np.float64` for all
inputs is justified by F-001 and PO-004. The issue requires boolean conversion,
while PO-004 records the frame condition that already-floating input should
remain on the existing working path.

The choice not to add a cast inside `_huber_loss_and_gradient` is justified by
F-002 and PO-007. The public issue is about `HuberRegressor.fit`; the helper is
private and is modeled with the precondition that `X` has already passed public
fit validation.

The sparse behavior was left to the same validation change, not a separate
branch, because PO-006 records that accepted CSR sparse input flows through
`_ensure_sparse_format(..., dtype=FLOAT_DTYPES, ...)`. The formal model covers
both dense and accepted CSR storage with the same dtype transition.

No test files were edited. F-004 is recorded only as future test guidance, and
the benchmark task forbids modifying tests.

## Artifacts

The requested FVK artifacts are complete:

- `fvk/SPEC.md`
- `fvk/FINDINGS.md`
- `fvk/PROOF_OBLIGATIONS.md`
- `fvk/PROOF.md`
- `fvk/ITERATION_GUIDANCE.md`

The FVK method's supporting adequacy and formal-core artifacts are also present:

- `fvk/INTENT_SPEC.md`
- `fvk/PUBLIC_EVIDENCE_LEDGER.md`
- `fvk/FORMAL_SPEC_ENGLISH.md`
- `fvk/SPEC_AUDIT.md`
- `fvk/PUBLIC_COMPATIBILITY_AUDIT.md`
- `fvk/mini-python.k`
- `fvk/huber-fit-spec.k`

The proof is constructed, not machine-checked. No tests, Python, `kompile`, or
`kprove` commands were run.

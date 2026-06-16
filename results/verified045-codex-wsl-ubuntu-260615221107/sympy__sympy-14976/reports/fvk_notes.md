# FVK Notes

## Decision

V1 stands unchanged. The FVK audit found the original source bug and relevant corner cases already addressed by the existing `MpmathPrinter._print_Rational` implementation.

## Trace to Findings and Proof Obligations

`fvk/FINDINGS.md` F-001 identifies the public bug: mpmath lambdify emitted a bare rational division such as `232/3`. This is discharged by `fvk/PROOF_OBLIGATIONS.md` PO-1, PO-2, PO-5, and PO-7: `lambdify(..., modules='mpmath')` reaches `MpmathPrinter`; non-integer rationals are printed as mpmath `mpf` operands; `mpf` is available in the mpmath namespace; and the rational printer is used inside larger generated expressions.

F-002 extends the issue from the positive reproducer to negative non-integer rationals. PO-2 and PO-3 cover that branch: V1 emits `-F(abs(p))/F(q)`, and existing printer sign/precedence handling preserves the value while keeping division in mpmath space.

F-003 records a proof limitation, not a source defect. The mini-K model proves generated expression shape and mpmath-valued division dispatch, but this task forbids running K, Python, tests, or mpmath. PO-8 keeps that caveat explicit. Because F-003 does not identify an intent-violating branch in the source, it does not justify a code edit.

F-004 confirms the frame condition. PO-6 shows the V1 change is isolated to `MpmathPrinter`, matching the issue's `modules='mpmath'` scope and avoiding unrelated printer behavior changes.

## Code Changes

No additional source edits were made during the FVK phase.

## Artifact Notes

The five requested FVK artifacts are present under `fvk/`:

- `SPEC.md`
- `FINDINGS.md`
- `PROOF_OBLIGATIONS.md`
- `PROOF.md`
- `ITERATION_GUIDANCE.md`

The FVK kit also requires adequacy and formal-core support, so the following supporting artifacts were added:

- `INTENT_SPEC.md`
- `PUBLIC_EVIDENCE_LEDGER.md`
- `FORMAL_SPEC_ENGLISH.md`
- `SPEC_AUDIT.md`
- `PUBLIC_COMPATIBILITY_AUDIT.md`
- `mini-python-printer.k`
- `mpmath-rational-printer-spec.k`

All proof results are labeled constructed, not machine-checked.

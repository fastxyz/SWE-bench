## Decision

V1 stands unchanged. No additional production source files were edited during
the FVK pass.

## Trace to FVK Findings and Proof Obligations

F-01 identifies the reported bug as an invalid Decimal context precision on
zero-valued Decimal inputs with explicit scale. PO-02 proves the V1 expression
`max(1, raw)` always satisfies Decimal's minimum precision requirement, and
PO-03 ties that back to the required precision-0 output `"0"`. This justifies
keeping the V1 source change.

F-02 is the non-regression check. PO-04 shows that when the old raw precision
was already valid, V1 leaves it unchanged. PO-05 shows the negative-precision
zero branch returns before the edited line, so that documented behavior is not
affected. These obligations justify not refactoring or special-casing zero
elsewhere.

PO-06 covers public compatibility. Because V1 changes only a local precision
expression and does not alter the `floatformat(text, arg=-1)` signature,
return shape, suffix parsing protocol, or known callsite contract, no
compatibility repair was needed.

F-03 records that this FVK pass uses a mini semantics for the reported
precision path rather than a full Python/Django/Decimal semantics. That is a
proof capability boundary, not evidence of a remaining code bug, so it did not
justify expanding the production patch.

F-04 recommends conventional regression tests for the two reported calls. The
benchmark instructions forbid modifying test files, so no test files were
changed.

## Commands

No tests, Python, or K commands were run. The exact K commands to run later are
recorded in `fvk/PROOF.md`.

# Iteration Guidance

Status: constructed, not machine-checked.

## Decision

Keep V1 unchanged.

The FVK audit found that the V1 edit directly discharges PO-2 and makes the already-correct `Poly.__rmul__` implementation reachable for the issue's ordinary-expression left operands. No additional production-code change is justified by the findings.

## If another iteration were allowed to edit tests

Do not remove tests. Add focused regression coverage for:

- `x*Poly(x, x) == Poly(x**2, x)`
- `S(-2)*Poly(x, x) == Poly(-2*x, x)`
- an incompatible left expression multiplied by `Poly` on the right, to pin the expression fallback

This benchmark forbids test edits, so these are guidance only.

## If machine checking becomes available

Run the commands recorded in `PROOF.md`. If the K parser or backend rejects the mini semantics, repair the FVK artifacts first; do not change production code unless the repaired proof surfaces a real mismatch with `INTENT_SPEC.md`.

## If a compatibility issue appears later

Investigate the broader class-level effect of `_op_priority` before changing source. The leading alternative is a multiplication-specific special case in core dispatch, but the FVK audit rejected it for this iteration because it duplicates SymPy's priority mechanism and is broader in core code than the one-line `Poly` priority declaration.

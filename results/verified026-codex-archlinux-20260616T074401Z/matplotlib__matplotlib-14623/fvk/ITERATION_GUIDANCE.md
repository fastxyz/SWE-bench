# Iteration Guidance

Status: guidance after FVK audit of V1.

## Verdict

V1 stands. The audit found no source-level problem requiring a V2 code edit.

## Why No Code Change Is Needed

- F1 and PO1 show that the original regression is exactly the loss of reversed
  order inside `LogLocator.nonsingular`.
- PO2 and PO3 show that preserving that order is sufficient for the final axis
  inversion observable because positive log-scale clamping is an identity.
- PO4 shows the patch does not invert normal increasing positive limits.
- PO5 shows invalid and singular branches are not part of the issue's positive
  finite unequal limit contract and remain framed.
- PO6 and PO7 show no tick-generation or public compatibility blocker.

## Suggested Future Public Tests

Do not modify tests in this benchmark. In normal development, add focused tests:

- `ax.set_yscale("log"); ax.set_ylim(100, 1); assert ax.get_ylim() == (100, 1)`
  and `assert ax.yaxis_inverted()`.
- The analogous x-axis case for `set_xlim`.
- A normal ordered log limit pair to confirm it remains non-inverted.

## Remaining Caveat

The proof is constructed but not machine-checked. Run the commands in
`PROOF.md` in a K-enabled environment before treating the `.k` proof as a
machine-verified result or removing any tests.


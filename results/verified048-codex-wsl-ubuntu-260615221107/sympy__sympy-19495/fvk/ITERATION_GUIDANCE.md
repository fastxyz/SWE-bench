# Iteration Guidance

Status: constructed, not machine-checked.

## Decision

V1 stands unchanged.

## Why No Source Edit Was Added

F1 is resolved by PO1 and PO2: the reported external guard case now returns the
substituted base, which preserves the `ImageSet` output shape.

F2 blocks the tempting broader edit of returning `base` for every true
condition. PO3 shows that V1's dummy-dependency split is necessary to preserve
public dummy-dependent assumption behavior.

F3 is a proof capability gap, not a code defect. It limits what the abstract
proof can claim, but it does not justify changing `ImageSet`, `Contains`, or the
unchanged `_eval_subs` branches.

F4 confirms there is no public compatibility issue requiring a source edit.

## Future Checks

In an environment where running code is allowed, useful tests would cover:

- the exact issue reproduction with `ConditionSet` over an `ImageSet`;
- a dummy-independent external guard over a `FiniteSet`;
- a dummy-dependent true condition with assumptions, preserving the legacy
  fallback behavior.

In an environment where K is installed, run the commands listed in `PROOF.md`.
Keep all tests until the K proof is actually machine-checked.


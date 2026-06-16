# Iteration Guidance

Status: final FVK repair guidance for this task.

## Decision

V1 stands unchanged.

The audit found the original bug as `FVK-F1`: `C` mode used a strict comparator
and therefore hid bins whose count was exactly `mincnt`. V1 directly repairs the
bug by using `>=`.

The audit also found that a naive inclusive change with the old internal default
`mincnt = 0` would have changed `C` mode with omitted `mincnt` to reduce empty
bins. `FVK-F2` and `PO-3` justify V1's internal default of `1` for that branch.

## No Additional Source Changes

No additional source edit is justified by the FVK artifacts:

- `PO-2` is discharged by the V1 comparator.
- `PO-3` is discharged by the V1 `mincnt is None` default threshold.
- `PO-4` confirms count-only behavior is preserved.
- `PO-6` confirms public signatures and pyplot forwarding are unchanged.
- `FVK-F3` identifies `mincnt=0` with `C` as edge-specified, not a blocker for
  the documented positive-`mincnt` contract.

## Recommended Future Work

Do not remove any public tests based on this constructed proof. Add regression
coverage for the issue in a normal development setting:

- `C=None`, `mincnt=1`, single-point bin is displayed.
- `C` supplied, `mincnt=1`, the same single-point bin is displayed.
- `C` supplied, `mincnt=None`, empty bins remain hidden.

To machine-check the FVK proof later, run the commands listed in `PROOF.md` in
an environment with K installed and adjust only K syntax issues if the local K
version requires it.

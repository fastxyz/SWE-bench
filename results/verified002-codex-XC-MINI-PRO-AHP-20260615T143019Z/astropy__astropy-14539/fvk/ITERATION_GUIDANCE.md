# Iteration Guidance

Status: constructed, not machine-checked.

## Code Decision

V1 should not stand unchanged. F-002 showed that V1 fixed the reported `Q`
dispatch but still used raw `np.allclose` as the whole VLA row predicate. The
source was revised to add `_vla_values_differ` and to call it from the `P`/`Q`
branch.

The V1 decision to include `Q` in the VLA branch is confirmed by F-001 and
PO-001. The exact normalized format-code check is confirmed by F-003 and
PO-008.

## Recommended Tests To Add Or Keep

Do not edit tests in this benchmark phase. In a normal development branch, add
or keep tests for:

1. `FITSDiff(path, path).identical` for a `QD` VLA column with unequal row
   lengths across rows, matching the public reproducer.
2. A floating `QD` or `PD` VLA row containing matching NaN or invalid values,
   expecting no difference on self-comparison.
3. Two VLA rows with different shapes, expecting a reported row difference.
4. Existing `P` VLA diff behavior, to confirm it remains row-wise.
5. A non-VLA fixed floating table column, to confirm dispatch remains unchanged.

Do not remove tests based on this FVK run because the proof was not
machine-checked.

## Next Verification Step

Run the recorded K commands from `fvk/PROOF.md` in an environment with K
installed. If `kprove` does not return `#Top`, treat the residual as a
proof-derived finding and revise either the mini semantics or the code.

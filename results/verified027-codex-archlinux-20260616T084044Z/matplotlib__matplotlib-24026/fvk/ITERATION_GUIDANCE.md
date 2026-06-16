# FVK Iteration Guidance

Status: V1 stands unchanged.

## Decision

No additional source edits are justified by the FVK findings. V1 fixes the two
intent-backed defects:

- F1: explicit `C<N>` colors no longer go through property-cycle validation.
- F2: explicit `colors=` no longer replaces or consumes the Axes line color
  cycle.

The broader possible change in F3, making `colors is None` preserve cycle
position too, is not applied. That behavior is not clearly required by public
intent and would change legacy default-color semantics.

## Next Code Changes, If Requested Later

- If maintainers want empty `colors=[]` to produce a clearer error, add an
  explicit `ValueError` before constructing the local cycle. This is outside
  the present issue's proved domain.
- If maintainers clarify that stackplot must never advance the Axes cycle even
  when `colors is None`, implement a snapshot or tee-based local cycle for the
  default path and update the public documentation. That would be a separate
  compatibility decision.
- The current use of `color_cycle.__next__` is behaviorally correct. A cosmetic
  refactor to a small helper using `next(color_cycle)` would not change the
  proof obligations and is not needed for this issue.

## Tests To Add In A Normal Development Environment

These are recommendations only; this benchmark forbids editing test files.

- `ax.stackplot(x, y, colors=['C2', 'C3'])` should not raise.
- Returned collections should receive facecolors matching `C2`, `C3`, then
  repeat for additional layers.
- After `ax.stackplot(..., colors=['C2'])`, the next automatic line color
  should be the same as it was before the stackplot call.
- Existing no-`colors` stackplot image behavior should remain unchanged.

## Formal Follow-Up

Run the emitted commands in `fvk/PROOF.md` in an environment with K installed
to upgrade the result from constructed proof to machine-checked proof. Until
then, treat any test-removal recommendation as conditional.

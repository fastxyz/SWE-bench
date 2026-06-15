# Iteration Guidance

Status: final FVK decision for this pass.

## V2 decision

Keep V1 unchanged.

The audit found that V1 exactly discharges the intent-derived missing case:
`self.mask` present and `operand.mask is None` must return
`deepcopy(self.mask)` rather than invoking `handle_mask`. This is F-001 and is
proved by PO-3 and PO-6. No additional production edit is justified by the
current public intent or proof obligations.

## Future test guidance

Do not modify tests in this benchmark. In a normal development pass, add public
tests for:

- integer bitmask propagation when the right operand is maskless;
- integer bitmask propagation when the right operand is a scalar;
- default boolean mask propagation when the right operand is maskless;
- reverse-order maskless/masked arithmetic to preserve symmetry.

## Future verification guidance

Run the commands in `fvk/PROOF.md` in a K-enabled environment. If `kprove`
returns `#Top`, the point tests above are subsumed by the proof for this helper
contract, but integration tests should remain.

## Open questions

None for the reported issue. The broader `NDArithmeticMixin` surface contains
other policies (`first_found`, WCS, uncertainty, collapse operations), but the
FVK proof did not produce a public-intent finding that requires changing those
paths in this repair.

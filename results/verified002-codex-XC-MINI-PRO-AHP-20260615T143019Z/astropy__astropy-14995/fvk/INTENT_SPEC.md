# Intent Specification

Status: intent-first, constructed from public evidence only.

## Required behavior

1. Callable mask propagation must support operands where exactly one side has
   `mask is None`.
2. If neither operand has a mask, the result mask is `None`.
3. If exactly one operand has a mask, the result mask is a copy of that mask.
   The mask-combining callable must not be invoked with `None`.
4. If both operands have masks and `handle_mask` is callable, the result mask is
   produced by calling `handle_mask(self.mask, operand.mask, **kwds)`.
5. If `handle_mask is None`, mask propagation is disabled and the result has no
   mask.
6. The sole present mask is preserved as a mask value; it is not normalized to a
   boolean array or an all-false missing-mask placeholder.
7. The behavior must be symmetric for the mask/no-mask cases relevant to binary
   arithmetic: masked left operand with unmasked right operand and unmasked left
   operand with masked right operand both copy the present mask.

## Domain assumptions

- The audited unit is `NDArithmeticMixin._arithmetic_mask`, reached from
  callable `handle_mask` paths in arithmetic methods such as `multiply`.
- `mask is None` denotes no mask.
- A non-`None` mask may be a boolean mask, an integer bitmask, or another mask
  object acceptable to the caller's `handle_mask`; the audited branch does not
  inspect its contents.
- `deepcopy(mask)` is represented in the formal model as `Copy(mask)`, which
  preserves the mask value while avoiding result aliasing.

## Out of scope for this repair

- Numeric data arithmetic is not re-specified here; the issue is solely about
  mask propagation.
- The exact semantics of arbitrary user-provided `handle_mask` callables are not
  modeled beyond whether they are invoked with two present masks.
- Termination is trivial for this branch-only helper and is not separately
  proved by machine execution.

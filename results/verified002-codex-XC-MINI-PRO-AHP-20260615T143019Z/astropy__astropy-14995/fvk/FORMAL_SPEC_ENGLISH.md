# Formal Spec English

Status: paraphrase of `fvk/ndarithmetic-mask-spec.k`; constructed, not
machine-checked.

## Claims

1. `MASK-NONE-HANDLE`: for any left mask and any right operand state, if
   `handle_mask` is disabled, `_arithmetic_mask` returns `NoMask`.
2. `MASK-BOTH-ABSENT`: if the left mask is `NoMask`, the right operand is
   absent, and `handle_mask` is callable, `_arithmetic_mask` returns `NoMask`.
3. `MASK-BOTH-NONE`: if the left mask is `NoMask`, the right operand exists
   with `NoMask`, and `handle_mask` is callable, `_arithmetic_mask` returns
   `NoMask`.
4. `MASK-RIGHT-ONLY`: if the left mask is `NoMask`, the right operand exists
   with a present mask, and `handle_mask` is callable, `_arithmetic_mask`
   returns `Copy(right_mask)`.
5. `MASK-LEFT-ONLY-ABSENT-OPERAND`: if the left mask is present, the right
   operand is absent, and `handle_mask` is callable, `_arithmetic_mask` returns
   `Copy(left_mask)`.
6. `MASK-LEFT-ONLY-MASKLESS-OPERAND`: if the left mask is present, the right
   operand exists but its mask is `NoMask`, and `handle_mask` is callable,
   `_arithmetic_mask` returns `Copy(left_mask)`.
7. `MASK-BOTH-PRESENT`: if both operand masks are present and `handle_mask` is
   callable, `_arithmetic_mask` returns `Combined(left_mask, right_mask)`.
8. `BINARY-SCALAR-MASKLESS-RIGHT`: if binary arithmetic wraps a scalar as a
   right operand with `NoMask`, callable mask propagation returns
   `Copy(left_mask)` when the left mask is present.

## Side conditions

- `Present` masks are constrained by `M =/=K NoMask`.
- `Copy(M)` is a value-preserving abstraction of `deepcopy(M)`.
- `Combined(M1, M2)` abstracts invoking the caller-provided mask-combining
  callable on two present masks.

## Loop and termination notes

The audited helper has no loop or recursion. The constructed proof is therefore
branch-case symbolic execution only. Termination is immediate in the modeled
fragment but not machine-checked.

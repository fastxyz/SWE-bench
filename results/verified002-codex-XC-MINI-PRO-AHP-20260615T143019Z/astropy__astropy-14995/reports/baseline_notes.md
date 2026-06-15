# Baseline Notes

## Root cause

`NDArithmeticMixin._arithmetic_mask` is intended to avoid calling `handle_mask`
when only one operand has a mask. That short-circuit worked when the left-hand
operand had no mask and the right-hand operand did, but the reverse case checked
only `operand is None`. For binary arithmetic against a maskless `NDData` operand
or a scalar wrapped as an `NDData` operand, `operand` exists while
`operand.mask is None`, so the method fell through to `handle_mask(self.mask,
operand.mask, ...)`. Callables such as `numpy.bitwise_or` then received a real
mask and `None`, causing the reported `TypeError` and producing object masks
with `None` values for boolean mask propagation.

## Changed files

`repo/astropy/nddata/mixins/ndarithmetic.py`

Updated `_arithmetic_mask` so the existing left-hand mask is deep-copied when
the right-hand operand is absent or its mask is `None`. This restores the
documented behavior that if only one mask is present, that mask is returned
without invoking the mask-combining callable.

## Assumptions and alternatives considered

I assumed that `mask=None` means "no mask" for both explicit `NDData` operands
and scalar operands that arithmetic wraps into the same class. That matches the
surrounding implementation and the method's return documentation.

I considered changing `handle_mask` behavior to tolerate `None`, but rejected
that because arbitrary user-supplied callables should not need to define
missing-mask semantics. The local helper already owns that policy.

I also considered normalizing missing masks to all-false boolean arrays, but
rejected that because it would change the dtype and representation of bitmask
inputs. Copying the only present mask preserves integer bitmasks as well as
boolean masks.

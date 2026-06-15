# FVK Specification

Status: constructed, not machine-checked.

## Target

The audited production unit is
`repo/astropy/nddata/mixins/ndarithmetic.py::_arithmetic_mask` plus the binary
arithmetic caller shape that wraps scalar operands as maskless operands before
calling `_arithmetic_mask` for callable `handle_mask`.

The V1 source state is:

```python
elif operand is None or operand.mask is None:
    return deepcopy(self.mask)
```

## Human-readable contract

For `handle_mask` policies:

- If `handle_mask is None`, the result mask is `None`.
- If `handle_mask` is callable and no operand has a mask, the result mask is
  `None`.
- If `handle_mask` is callable and only the right operand has a mask, the result
  is a deep copy of the right operand's mask.
- If `handle_mask` is callable and only the left operand has a mask, the result
  is a deep copy of the left operand's mask. This includes the bug-reported case
  where the right operand exists but `operand.mask is None`.
- If `handle_mask` is callable and both operands have masks, the result is
  produced by `handle_mask(self.mask, operand.mask, **kwds)`.

## Public intent ledger

The ledger entries are mirrored in `fvk/PUBLIC_EVIDENCE_LEDGER.md`:

- L1: one missing mask must not make callable mask propagation fail.
- L2: exactly one present mask is copied to the output.
- L3: two missing masks produce no output mask.
- L4: two present masks are combined by the callable.
- L5: boolean masks must not become object arrays with `None` entries.
- L6: integer bitmasks are in domain and must not be coerced to boolean.
- L7: `_arithmetic_mask`'s return documentation assigns zero-mask, one-mask, and
  two-mask behavior.
- L8: `handle_mask=None` disables mask propagation.

## Formal abstraction

The K model in `fvk/mini-python-mask.k` abstracts masks as:

- `NoMask`: Python `None`.
- `Present(I)`: any non-`None` mask value, represented by an identifier.
- `Copy(M)`: value-preserving deep copy of a present mask.
- `Combined(M1, M2)`: result of invoking an arbitrary callable `handle_mask` on
  two present masks.

This abstraction intentionally preserves the discriminator relevant to the bug:
`NoMask` is distinct from every present mask, and `Combined(M, NoMask)` is not an
allowed successful result for callable propagation.

## Preconditions

- The function is called through the audited `NDArithmeticMixin` path.
- The right operand is either absent (`operand is None`) or has a `.mask`
  attribute. This is consistent with the caller converting binary scalar
  operands into the same class before calling `_arithmetic`.
- `handle_mask` is either `None` or callable for the formal claims.

## Frame conditions

- The patch does not alter arithmetic data, units, uncertainty propagation,
  metadata, WCS handling, or public method signatures.
- The patch does not alter `handle_mask="first_found"` behavior.
- The patch does not inspect or coerce mask contents.

## K artifacts

- Semantics: `fvk/mini-python-mask.k`.
- Claims: `fvk/ndarithmetic-mask-spec.k`.
- English paraphrase: `fvk/FORMAL_SPEC_ENGLISH.md`.
- Adequacy audit: `fvk/SPEC_AUDIT.md`.

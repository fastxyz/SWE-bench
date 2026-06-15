# FVK Notes

## Decision

V1 stands unchanged as V2.

The FVK audit identified the operative bug as F-001: the left operand had a
mask, the right operand existed with `mask=None`, and callable mask propagation
fell through to `handle_mask(self.mask, None)`. PO-3 is the corresponding proof
obligation, and V1 discharges it with:

```python
elif operand is None or operand.mask is None:
    return deepcopy(self.mask)
```

PO-6 extends the same obligation to scalar arithmetic, because scalars are
wrapped as maskless operands before `_arithmetic_mask` is called. That directly
covers the reported `nref_mask.multiply(1., handle_mask=np.bitwise_or)` case.

## Why no further source edit was made

F-002 and PO-7 require preserving boolean and integer mask values instead of
normalizing missing masks to `False` arrays or coercing bitmasks to boolean.
V1 uses `deepcopy(self.mask)` for the sole-present left mask, so the value domain
is preserved. Adding normalization would contradict F-003 and PO-7.

F-004 and PO-8 found no public signature, dispatch, or override compatibility
problem. The only source change needed remains the V1 private-helper branch; no
public API or non-callable mask policy needed revision.

PO-4 confirms that both-present masks still reach `handle_mask`, so the V1
condition does not swallow legitimate bitwise/logical mask combination. PO-5
confirms `handle_mask=None` is unchanged.

## Verification caveat

The K artifacts and proof are constructed, not machine-checked, because this
benchmark forbids running K tooling. The commands to machine-check later are in
`fvk/PROOF.md`. No tests were run or modified.

# Proof Obligations

Status: constructed, not machine-checked.

## PO-1: Zero masks return no mask

- Claim: if neither side has a mask, `_arithmetic_mask` returns `NoMask`.
- Evidence: L3, L7.
- Formal claims: `MASK-BOTH-ABSENT`, `MASK-BOTH-NONE`.
- V1 status: discharged.

## PO-2: Right-only mask is copied

- Claim: if `self.mask is None` and `operand.mask` is present,
  `_arithmetic_mask` returns a deep copy of `operand.mask`.
- Evidence: L2, L7.
- Formal claim: `MASK-RIGHT-ONLY`.
- V1 status: discharged by the existing `elif self.mask is None and operand is
  not None` branch.

## PO-3: Left-only mask is copied when right operand exists with no mask

- Claim: if `self.mask` is present and `operand.mask is None`,
  `_arithmetic_mask` returns a deep copy of `self.mask`.
- Evidence: L1, L2, L5, L7.
- Formal claim: `MASK-LEFT-ONLY-MASKLESS-OPERAND`.
- V1 status: discharged by changing `elif operand is None` to
  `elif operand is None or operand.mask is None`.

## PO-4: Both present masks delegate to callable

- Claim: if both operand masks are present and `handle_mask` is callable,
  `_arithmetic_mask` returns the callable result.
- Evidence: L4, L7.
- Formal claim: `MASK-BOTH-PRESENT`.
- V1 status: discharged; the new condition excludes only `operand.mask is None`,
  so present/present masks still fall through to `handle_mask`.

## PO-5: `handle_mask=None` disables mask propagation

- Claim: if `handle_mask is None`, result mask is `NoMask`.
- Evidence: L8.
- Formal claim: `MASK-NONE-HANDLE`.
- V1 status: discharged; V1 does not alter this earlier branch.

## PO-6: Scalar binary arithmetic follows left-only mask rule

- Claim: binary arithmetic against a scalar wraps the scalar as a maskless
  operand; if the left operand has a mask, callable mask propagation returns a
  copy of the left mask.
- Evidence: L1, L2, L7.
- Formal claim: `BINARY-SCALAR-MASKLESS-RIGHT`.
- V1 status: discharged because the wrapped operand has `operand.mask is None`
  and therefore reaches PO-3.

## PO-7: Preserve mask value domain

- Claim: copying the sole present mask preserves arbitrary non-`None` mask
  values, including integer bitmasks and boolean masks, without coercion.
- Evidence: L5, L6, L7.
- Formal support: `Copy(M)` preserves `M`; no claim rewrites `Present(I)` into a
  boolean or all-false placeholder.
- V1 status: discharged; `deepcopy(self.mask)` and `deepcopy(operand.mask)` do
  not inspect or coerce mask contents.

## PO-8: No API compatibility regression

- Claim: V1 does not change public signatures, subclass override contracts, or
  non-callable mask handling.
- Evidence: public compatibility audit.
- Formal support: frame conditions in `SPEC.md`.
- V1 status: discharged by static source inspection.

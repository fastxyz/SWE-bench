# Proof Obligations

Status: constructed, not machine-checked.

## PO-1: Default no-symbol conversion

- Claim: if the varargs tuple is empty, `PolyElement.as_expr()` passes
  `self.ring.symbols` to `expr_from_dict`.
- Evidence: I-2, E-5.
- Discharge: V1 explicitly enters `if not symbols` and assigns
  `symbols = self.ring.symbols` before the single return.
- Status: discharged by source inspection and claim `POLY-AS-EXPR-DEFAULT`.

## PO-2: Same-arity supplied symbols are preserved

- Claim: if `symbols` is non-empty and `len(symbols) == self.ring.ngens`,
  `PolyElement.as_expr(*symbols)` passes the supplied tuple to
  `expr_from_dict`.
- Evidence: I-1, I-4, E-1, E-2, E-3.
- Discharge: in V1, the same-arity branch skips both the empty-varargs fallback
  and the wrong-arity raise; no assignment overwrites `symbols` before return.
- Status: discharged by source inspection and claim `POLY-AS-EXPR-SUPPLIED`.

## PO-3: Wrong arity still raises `ValueError`

- Claim: if `symbols` is non-empty and `len(symbols) != self.ring.ngens`,
  `PolyElement.as_expr(*symbols)` raises `ValueError`.
- Evidence: I-3, E-4.
- Discharge: V1 preserves the existing `elif len(symbols) != self.ring.ngens`
  branch and its `ValueError`.
- Status: discharged by source inspection and claim `POLY-AS-EXPR-BAD-ARITY`.

## PO-4: Expression construction uses the chosen symbol tuple positionally

- Claim: the symbol tuple reaching `expr_from_dict` is what determines the
  expression variables positionally.
- Evidence: I-4, E-7.
- Discharge: `expr_from_dict` iterates `zip(gens, monom)` and applies `Pow(g, m)`
  for nonzero exponents, so the `gens` tuple supplied by `PolyElement.as_expr`
  is the variable source.
- Status: discharged by helper source inspection.

## PO-5: Fraction-field forwarding remains correct

- Claim: `FracElement.as_expr(*symbols)` benefits from the same preserved-symbol
  behavior because it forwards the exact varargs tuple to numerator and
  denominator `as_expr` calls.
- Evidence: I-6, E-8.
- Discharge: the wrapper source is unchanged and calls
  `self.numer.as_expr(*symbols)/self.denom.as_expr(*symbols)`.
- Status: discharged by source inspection and claim `FRAC-AS-EXPR-SUPPLIED`.

## PO-6: Public API compatibility

- Claim: the fix does not change the public signature, call convention, return
  shape, or test files.
- Evidence: I-5 and `PUBLIC_COMPATIBILITY_AUDIT.md`.
- Discharge: V1 changes only the internal branch assignment in
  `PolyElement.as_expr`.
- Status: discharged.

# Proof Obligations

Status: constructed, not machine-checked.

## PO1: no additive distribution for numeric denominator products

- Statement: if an additive term's denominator product evaluates to a number,
  `_eval_product` must return `None`.
- Public provenance: E3 and E4 in `PUBLIC_EVIDENCE_LEDGER.md`.
- Code location: `repo/sympy/concrete/products.py`, lines 277-281.
- Formal claim: C1 in `product-add-spec.k`.
- Discharge: direct by rule `ADD-Q-NUMBER` in `mini-sympy-product.k`.

## PO2: no quotient when numerator product cannot be evaluated

- Statement: if denominator clearing gives a nonnumeric denominator product but
  the numerator product evaluates to `None`, the additive branch must return
  `None`.
- Public provenance: E1, E3, and E5.
- Code location: `repo/sympy/concrete/products.py`, lines 283-285.
- Formal claim: C3 in `product-add-spec.k`.
- Discharge: direct by rule `ADD-P-NONE`.

## PO3: preserve rational additive quotient path

- Statement: if the denominator product is nonnumeric and the numerator product
  evaluates, return `p_product / q_product`.
- Public provenance: E6.
- Code location: `repo/sympy/concrete/products.py`, lines 283-286.
- Formal claim: C4 in `product-add-spec.k`.
- Discharge: direct by rule `ADD-RATIONAL`.

## PO4: preserve unevaluated fallback from `Product.doit()`

- Statement: if `_eval_product` returns `None`, `Product.doit()` returns an
  unevaluated `Product` over the remaining limits.
- Public provenance: E5 and E7.
- Code location: `repo/sympy/concrete/products.py`, lines 217-219.
- Formal claim: C5 in `product-add-spec.k`.
- Discharge: direct by rule `DOIT-UNEVALUATED`.

## PO5: reported q-exponential product does not produce false closed form

- Statement: for `Product(n + 2**(-k), (k, 0, n - 1))`, the additive branch
  reaches `None` and `Product.doit()` returns unevaluated rather than producing
  `2**(n*(-n + 1)/2) + n**n`.
- Public provenance: E1, E2, E3, and E5.
- Code location: composition of lines 277-286 and 217-219.
- Formal claims used: C1, C3, and C5.
- Discharge: denominator clearing exposes an outer nonnumeric denominator
  product; recursive numerator evaluation hits PO1 on the still-additive
  numerator with denominator `1`; PO2 returns `None` from the outer branch; PO4
  returns unevaluated `Product`.

## PO6: public compatibility

- Statement: the fix must not change public signatures, call conventions, or
  successful rational-product behavior.
- Public provenance: E5, E6, and `PUBLIC_COMPATIBILITY_AUDIT.md`.
- Code location: body-only change in `Product._eval_product`.
- Formal claims used: C4 and C5.
- Discharge: no signature changes; quotient and fallback paths are both
  preserved.


# Public Evidence Ledger

## E1: Reported wrong product

- Source: prompt / `benchmark/PROBLEM.md`
- Evidence: `Product(n + 1 / 2**k, [k, 0, n-1]).doit()` simplifies to
  `2**(n*(-n + 1)/2) + n**n` and `p.subs(n,2)` prints `9/2`.
- Obligation: the evaluator must not produce that false symbolic closed form.
- Status: encoded by PO1, PO2, PO4, and PO5.

## E2: Concrete multiplicative meaning

- Source: prompt / `benchmark/PROBLEM.md`
- Evidence: for `n = 2`, the product is
  `(2 + 2**0) * (2 + 2**(-1)) = 15/2`.
- Obligation: concrete evaluation must follow multiplicative product semantics,
  not addition of independent products.
- Status: encoded by PO5 and preserved by the concrete-range branch in
  `Product._eval_product`.

## E3: Invalid algebraic rule

- Source: prompt hint / `benchmark/PROBLEM.md`
- Evidence: the responsible line "seems to be assuming that the product of a
  sum is the same as the sum of the products of its summands."
- Obligation: the fallback must not distribute `Product` over `Add`.
- Status: encoded by PO1 and PO2.

## E4: Second nonsensical example

- Source: prompt hint / `benchmark/PROBLEM.md`
- Evidence: `Product(k**(S(2)/3) + 1, [k, 0, n-1]).doit()` simplified to `1`.
- Obligation: additive terms that do not become evaluable after denominator
  clearing must remain unevaluated rather than becoming false closed forms.
- Status: encoded by PO1 and PO4.

## E5: Public fallback contract

- Source: `repo/sympy/concrete/products.py`, product docstring, lines 488-494.
- Evidence: "If it cannot compute the product, it returns an unevaluated
  Product object."
- Obligation: returning unevaluated `Product` is the intended safe fallback
  when a q-Pochhammer or other exact product form is unavailable.
- Status: encoded by PO4.

## E6: Rational product compatibility

- Source: `repo/sympy/concrete/tests/test_sums_products.py`, lines 458-465.
- Evidence: public tests expect products such as `product(1 + 1/n, (n, a, b))`
  and related rational products to evaluate.
- Obligation: denominator clearing for rational products must remain available.
- Status: encoded by PO3.

## E7: Existing conservative-product precedent

- Source: `repo/sympy/concrete/tests/test_sums_products.py`, lines 454-455.
- Evidence: "If Product managed to evaluate this one, it most likely got it
  wrong!" and `Product(n**n, (n, 1, b))` remains a `Product`.
- Obligation: conservative non-evaluation is preferable to an unsupported
  symbolic product rule.
- Status: supports PO4 and the no-source-change decision.

## E8: No q-Pochhammer primitive in this checkout

- Source: source search under `repo/sympy`.
- Evidence: only ordinary RisingFactorial / Pochhammer references are present;
  no q-Pochhammer implementation is exposed.
- Obligation: do not invent a broad new special-function API in this targeted
  bug fix; use the documented unevaluated fallback.
- Status: recorded as F4 in `FINDINGS.md`.


# Intent Spec

Status: constructed from public evidence only. Candidate behavior is treated as
observed behavior to audit, not as the source of truth.

## Required behavior

1. `Product.doit()` must not return a closed form that is algebraically false
   for a product over an additive term.

2. In particular, the product
   `Product(n + 1/2**k, (k, 0, n - 1))` must not simplify to
   `2**(n*(-n + 1)/2) + n**n`, because substituting `n = 2` gives `9/2`
   while the multiplicative product is `(2 + 2**0)*(2 + 2**(-1)) = 15/2`.

3. The additive product rule
   `Product(a(k) + b(k), k) = Product(a(k), k) + Product(b(k), k)` is not
   valid and must not be used as a fallback.

4. If SymPy cannot compute a sound closed form for a product, returning an
   unevaluated `Product` is acceptable public behavior.

5. Existing rational product support must be preserved when an additive
   rational expression can be transformed into an evaluable numerator product
   divided by an evaluable nontrivial denominator product.

## Scope

The audited unit is the additive branch of `Product._eval_product` and the
`Product.doit()` fallback that consumes `None` from `_eval_product`. The full
SymPy expression system is outside the mini-semantics; its recursive product
results are abstracted as `none`, `number`, and `nonnumber`.

## Default-domain assumptions

- Finite concrete products are interpreted multiplicatively over the included
  integer range, consistent with the `Product` docstring.
- Partial correctness only: the artifacts reason about the returned value if
  the evaluator returns.
- Unevaluated `Product` is a valid fallback when no sound product rule is
  available.


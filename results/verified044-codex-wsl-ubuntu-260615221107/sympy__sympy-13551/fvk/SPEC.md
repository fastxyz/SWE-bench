# FVK Spec

Status: constructed, not machine-checked. No tests, Python code, or K tooling
were run.

## Target

The audited target is the V1 change in
`repo/sympy/concrete/products.py`, specifically:

- `Product._eval_product`, additive branch at lines 277-286;
- `Product.doit`, fallback at lines 217-219 when `_eval_product` returns
  `None` or `S.NaN`.

The mini-semantics abstracts recursive SymPy product results as:

- `none`: `_eval_product(...)` returned `None`;
- `number`: `_eval_product(...)` returned a numeric expression;
- `nonnumber`: `_eval_product(...)` returned a nonnumeric evaluable expression;
- `quotient(P, Q)`: the branch returned `P/Q`.

This abstraction keeps the property under audit visible: whether the additive
branch distributes over a sum, returns a quotient, or declines evaluation.

## Intent ledger

The standalone intent and evidence files are:

- `fvk/INTENT_SPEC.md`
- `fvk/PUBLIC_EVIDENCE_LEDGER.md`
- `fvk/FORMAL_SPEC_ENGLISH.md`
- `fvk/SPEC_AUDIT.md`
- `fvk/PUBLIC_COMPATIBILITY_AUDIT.md`

The key obligations are:

1. Do not compute products over sums by adding products of summands.
2. Preserve safe unevaluated fallback when no sound closed form is available.
3. Preserve rational product evaluation when denominator clearing creates an
   evaluable numerator over an evaluable nontrivial denominator product.
4. Do not introduce public API or return-shape incompatibilities.

## Formal core

The formal core is:

- `fvk/mini-sympy-product.k`: a minimal K semantics for the additive branch and
  the `Product.doit()` fallback.
- `fvk/product-add-spec.k`: reachability claims for the branch outcomes.

The exact machine-check commands, not executed here, are:

```sh
(cd fvk && kompile mini-sympy-product.k --backend haskell)
(cd fvk && kast --backend haskell product-add-spec.k)
(cd fvk && kprove product-add-spec.k)
```

Expected machine-check result after a future run: `#Top` for all claims.

## Behavioral contract

For an additive term `term`, `Product._eval_product` first computes
`p, q = term.as_numer_denom()` and recursively evaluates the denominator
product.

The intended branch behavior is:

1. If the denominator product is `None`, return `None`.
2. If the denominator product is numeric, return `None`.
3. If the denominator product is nonnumeric and the numerator product is
   `None`, return `None`.
4. If the denominator product is nonnumeric and the numerator product evaluates
   to `P`, return `P/q_product`.

`Product.doit()` then maps `None` from `_eval_product` to an unevaluated
`Product`, which is the documented safe fallback.

## Reported issue path

For `Product(n + 2**(-k), (k, 0, n - 1))`:

1. Denominator clearing gives an outer denominator product for `2**k`, which is
   nonnumeric for symbolic `n`.
2. The cleared numerator still contains an unevaluable additive expression of
   the form `n*2**k + 1`.
3. The inner additive branch sees denominator `1`, whose product is numeric, and
   returns `None`.
4. The outer additive branch receives numerator product `None` and returns
   `None`.
5. `Product.doit()` returns an unevaluated `Product` instead of the false closed
   form.

For a later concrete finite evaluation after substituting `n = 2`, the existing
integer-difference branch enumerates the two factors and yields the
multiplicative product `(2 + 2**0)*(2 + 2**(-1)) = 15/2`.

## Adequacy result

The formal English claims match the public intent for the audited branch. The
only stronger mathematical result named by the prompt is a q-Pochhammer closed
form; since this checkout has no q-Pochhammer primitive and `Product` documents
unevaluated fallback, that is recorded as an enhancement boundary rather than a
required source edit.


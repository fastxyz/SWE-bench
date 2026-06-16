# Constructed Proof

Status: constructed, not machine-checked. No tests, Python, `kompile`, `kast`,
or `kprove` commands were executed.

## Machine-check commands

These commands are recorded for a future environment with K installed:

```sh
(cd fvk && kompile mini-sympy-product.k --backend haskell)
(cd fvk && kast --backend haskell product-add-spec.k)
(cd fvk && kprove product-add-spec.k)
```

Expected result after successful machine checking: `#Top`.

## Claims proved by construction

### C1: numeric denominator product

Initial state:

```k
<k> addProduct(P, number) </k>
```

Rule `ADD-Q-NUMBER` rewrites this in one step to:

```k
<k> none </k>
```

This discharges PO1.

### C2: denominator product cannot be evaluated

Initial state:

```k
<k> addProduct(P, none) </k>
```

Rule `ADD-Q-NONE` rewrites this in one step to:

```k
<k> none </k>
```

This supports the same fallback discipline as PO1.

### C3: numerator product cannot be evaluated

Initial state:

```k
<k> addProduct(none, Q) </k>
```

Under side condition `notBool isNumber(Q)`, rule `ADD-P-NONE` rewrites this in
one step to:

```k
<k> none </k>
```

This discharges PO2.

### C4: rational additive success path

Initial state:

```k
<k> addProduct(P, Q) </k>
```

Under side conditions `notBool isNumber(Q)` and `P =/=K none`, rule
`ADD-RATIONAL` rewrites this in one step to:

```k
<k> quotient(P, Q) </k>
```

This discharges PO3.

### C5: `Product.doit()` fallback

Initial state:

```k
<k> productDoit(none) </k>
```

Rule `DOIT-UNEVALUATED` rewrites this in one step to:

```k
<k> unevaluated </k>
```

This discharges PO4.

## Issue derivation

For `Product(n + 2**(-k), (k, 0, n - 1))`, denominator clearing gives an outer
numerator of the form `n*2**k + 1` and an outer denominator `2**k`.

The outer denominator product is nonnumeric for symbolic `n`, so the additive
branch tries to evaluate the numerator product. That numerator is still an
additive expression. Its own denominator after `as_numer_denom()` is `1`, whose
product is numeric. By C1, the recursive numerator product returns `none`.

The outer additive branch is therefore in the C3 state `addProduct(none, Q)`
with nonnumeric `Q`, so it returns `none`. By C5, `Product.doit()` returns an
unevaluated product instead of the false closed form.

For a later concrete finite evaluation with `n = 2`, the existing
integer-difference branch in `_eval_product` enumerates the two factors, giving
`(2 + 2**0)*(2 + 2**(-1)) = 15/2`. This is not a new V1 rule; it is the
pre-existing finite-product semantics preserved by avoiding the false symbolic
closed form.

## Second prompt example

For `Product(k**(S(2)/3) + 1, (k, 0, n - 1))`, denominator clearing leaves
denominator `1`. By C1 the additive branch returns `none`, and by C5
`Product.doit()` returns unevaluated. The pre-V1 result `1` is therefore not
reachable through the V1 branch semantics.

## Compatibility proof

For rational products such as `1 + 1/n`, denominator clearing produces a
nontrivial denominator product and a polynomial numerator product. When those
recursive products are represented as non-`none` values in the abstraction, C4
returns their quotient. This is the same successful path the public rational
product tests rely on.

## Residual risk

This proof is over a mini-semantics for the changed branch, not full Python or
full SymPy. It proves partial correctness of the branch outcomes relative to
the abstraction. The artifacts are constructed, not machine-checked, and no test
removal is recommended.


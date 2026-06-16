# Iteration Guidance

## Decision

Keep V1 unchanged.

The FVK audit found that V1 satisfies the intent-derived proof obligations:

- PO1 and PO2 remove the invalid product-over-addition fallback.
- PO3 preserves rational additive products.
- PO4 preserves the documented unevaluated fallback.
- PO5 covers the reported q-exponential product.
- PO6 shows no public compatibility edit is needed.

## Source changes

No additional source changes are recommended.

Adding a q-Pochhammer closed form would be a future feature, not a required
repair for this issue in this checkout, because no q-Pochhammer primitive exists
and unevaluated `Product` is a documented fallback.

## Tests to add in a normal development environment

Do not edit tests in this task. For a future ordinary development pass, useful
tests would be:

1. `Product(n + 2**(-k), (k, 0, n - 1)).doit()` remains an unevaluated
   `Product`, or at least does not equal the false closed form.
2. After substituting `n = 2`, explicitly calling `.doit()` on the remaining
   finite product gives `15/2`.
3. `Product(k**(S(2)/3) + 1, (k, 0, n - 1)).doit()` remains unevaluated.
4. Existing rational product cases such as `product(1 + 1/n, (n, a, b))`
   continue to evaluate.

## Future machine check

When a K environment is available, run:

```sh
(cd fvk && kompile mini-sympy-product.k --backend haskell)
(cd fvk && kast --backend haskell product-add-spec.k)
(cd fvk && kprove product-add-spec.k)
```

Keep all tests until the proof is actually machine-checked.


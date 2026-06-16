# FVK Proof

Status: constructed, not machine-checked.

## Theorem

For the audited handlers, partial correctness holds over the stated domain:

1. `is_subset_sets(ProductSet, FiniteSet)` returns the correct fuzzy subset
   result for definitely non-finite products, unknown-finiteness products, and
   definitely finite products whose enumeration either succeeds or cannot be
   safely completed.
2. `_eval_is_eq(ProductSet, FiniteSet)` and `_eval_is_eq(FiniteSet, ProductSet)`
   return the SymPy truth conversion of mutual fuzzy subsethood.

## Constructed Proof

### PO1: Definitely non-finite product

The changed handler first stores `is_finite = a_product.is_finite_set`. If that
value is exactly `False`, it returns `False`. This matches the general set fact
already used by `Set.is_subset`: a definitely non-finite set is not a subset of
a finite set.

### PO2: Unknown product finiteness

If `is_finite` is neither `False` nor truthy, the handler falls through without
returning a value, which is Python `None`. That preserves SymPy's fuzzy
indeterminate subset behavior for symbolic cases.

### PO3: Definitely finite and enumerable product

If `is_finite` is truthy, the handler computes:

```python
fuzzy_and(b_finiteset.contains(x) for x in a_product)
```

`ProductSet.__iter__` delegates to `iproduct(*self.sets)`, so when enumeration
succeeds it yields every Cartesian-product element. `FiniteSet.contains(x)`
sympifies tuple-like product elements and returns fuzzy membership. The
`fuzzy_and` contract is exactly universal quantification over the finite list:
`False` if any element is definitely absent, `True` if all are present, and
`None` if no absence is known but some membership is undecidable. Therefore the
handler computes the intended subset predicate.

### PO4: Definitely finite but not safely enumerable

Some SymPy sets are known finite while their iterator can still raise because
symbolic membership or cardinality is undecidable. V2 wraps the enumeration in:

```python
try:
    ...
except (TypeError, ValueError):
    return None
```

The exception path is therefore converted to the same fuzzy indeterminate value
used elsewhere by set queries, preserving the `is_subset` API contract.

### PO5: Equality through mutual subsethood

The comparison handlers compute:

```python
tfn[fuzzy_and([lhs.is_subset(rhs), rhs.is_subset(lhs)])]
```

For sets, equality is equivalent to both subset directions. The first direction
uses PO1-PO4 for `ProductSet <= FiniteSet`; the second direction uses the
existing `FiniteSet._eval_is_subset`, which checks every explicit finite-set
element against the product. `tfn` converts a definite fuzzy result to the
SymPy boolean used by equality dispatch and leaves indeterminate cases as
`None`.

## Adequacy

The proof obligations match the intent ledger in `fvk/SPEC.md`: they cover the
public issue's concrete finite product, the finite-target negative case,
symbolic/unknown cases, and the equality simplification symptom. They do not
claim a broader rewrite of generic relational simplification.

## Residual Risk

This is a constructed proof over a small abstract model, not a machine-checked
proof against full Python or full SymPy semantics. Termination is not separately
proved. No tests were run. Test removal is not recommended.

## Reproduce The Machine Check Later

These commands were not run in this session:

```sh
kompile fvk/mini-sympy-sets.k --backend haskell
kast --backend haskell fvk/productset-finiteset-spec.k
kprove fvk/productset-finiteset-spec.k
```

Expected later result: `kprove` returns `#Top` for the claims in
`fvk/productset-finiteset-spec.k`.


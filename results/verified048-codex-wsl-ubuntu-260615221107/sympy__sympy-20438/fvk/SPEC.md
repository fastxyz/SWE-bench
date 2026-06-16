# FVK Spec: ProductSet.is_subset(FiniteSet)

Status: constructed, not machine-checked.

## Scope

This FVK pass audits the V1 changes to:

- `repo/sympy/sets/handlers/issubset.py`
- `repo/sympy/sets/handlers/comparison.py`

The verified units are the cross-type subset handler
`is_subset_sets(ProductSet, FiniteSet)` and the cross-type equality handlers
`_eval_is_eq(ProductSet, FiniteSet)` / `_eval_is_eq(FiniteSet, ProductSet)`.

## Intent Spec

1. `ProductSet(...).is_subset(FiniteSet(...))` must return a fuzzy truth value
   (`True`, `False`, or `None`) instead of falling through to an indeterminate
   result for concrete finite products.
2. If a product set is definitely not finite, it cannot be a subset of a finite
   set.
3. If a product set is definitely finite and can be enumerated, subsethood is
   exactly the fuzzy conjunction of membership of every product element in the
   finite set.
4. If the product set is only symbolically/undecidably enumerable, the subset
   result should remain fuzzy indeterminate (`None`), not raise.
5. Equality between a finite product and an explicit finite set should resolve
   from mutual subsethood, so equivalent finite Cartesian products compare equal
   and the issue's `Eq(...).simplify()` path does not reach a set difference
   object lacking `.equals`.

## Public Evidence Ledger

| ID | Source | Evidence | Obligation | Status |
|---|---|---|---|---|
| E1 | prompt | "`is_subset` gives wrong results" | The repair target is set subset semantics, not unrelated simplification behavior. | Encoded in PO1-PO4. |
| E2 | prompt | `b.is_subset(c)` prints no result for `b = ProductSet(a, a)` and matching explicit `FiniteSet` `c` | A concrete finite product must prove subsethood against its equivalent explicit finite set. | Encoded in PO3. |
| E3 | public hint | "is_subset doesn't work ProductSet.is_subset(FiniteSet)" | The missing direction is `ProductSet` as left operand and `FiniteSet` as right operand. | Encoded in PO1-PO4. |
| E4 | prompt | `c.is_subset(b)` returns `True` | Existing finite-to-product membership semantics are valid supporting behavior for equality via mutual subsethood. | Encoded in PO5. |
| E5 | prompt | `Eq(b, c).simplify()` raises `AttributeError: 'Complement' object has no attribute 'equals'` | Equivalent product/finite-set equality should resolve before generic relational simplification computes an unevaluated set complement. | Encoded in PO5. |
| E6 | API/docstring | `Set.is_subset` returns whether one set is a subset of another, with existing examples returning `None` for undecidable symbolic finite-set cases | Unknown symbolic cases should remain fuzzy indeterminate rather than raising. | Encoded in PO4. |

## Formal Spec English

The formal core is in `fvk/mini-sympy-sets.k` and
`fvk/productset-finiteset-spec.k`.

- `PSUBSET-NONFINITE`: for any product set whose `is_finite_set` value is
  definitely false and any finite set target, the subset result is false.
- `PSUBSET-UNKNOWN-FINITE`: for any product set whose finiteness is unknown and
  any finite set target, the specialized handler does not decide the result.
- `PSUBSET-FINITE-ENUM`: for any definitely finite product whose enumerator
  yields the exact product elements, the subset result is the fuzzy conjunction
  of `target.contains(element)` over those elements.
- `PSUBSET-FINITE-ENUM-FAIL`: for any definitely finite product whose iterator
  cannot safely enumerate because membership/cardinality is symbolic or
  undecidable, the result is `None`.
- `PEQ-FSET` and `FSET-PEQ`: product/finite equality is the `tfn` conversion of
  fuzzy conjunction of both subset directions.

## Adequacy Audit

| Claim | Intent coverage | Result |
|---|---|---|
| PO1 `PSUBSET-NONFINITE` | E3 plus finite-target set theory: an infinite/non-finite set cannot be a subset of a finite set. | Pass |
| PO2 `PSUBSET-UNKNOWN-FINITE` | E6: undecidable symbolic cases remain `None`. | Pass |
| PO3 `PSUBSET-FINITE-ENUM` | E1-E3: concrete finite products are decided by all element membership. | Pass |
| PO4 `PSUBSET-FINITE-ENUM-FAIL` | E6 and FVK audit finding F2: unsafe symbolic enumeration must not escape as `TypeError`/`ValueError`. | Pass after V2 edit |
| PO5 equality via mutual subset | E4-E5: equivalent product/finite sets should compare equal and avoid the simplify traceback. | Pass |

No claim relies on hidden tests, benchmark verdicts, or upstream fixes.

## Compatibility Audit

No public function signatures, method names, return shapes, or virtual-call
protocols were changed. The changes add multipledispatch specializations for
already-public set operations. Existing callers of `is_subset`, `Eq`, and
`is_eq` continue to receive fuzzy booleans or SymPy booleans as before.


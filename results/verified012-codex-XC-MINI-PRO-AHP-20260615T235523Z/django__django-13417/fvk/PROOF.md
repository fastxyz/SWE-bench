# Constructed Proof

Status: constructed, not machine-checked. Per instruction, no tests, Python, or
K tooling were run.

## Theorem

For every audited query state, V1 `QuerySet.ordered` returns `True` exactly when
the queryset has an effective semantic ordering source:

```text
isEmpty
or hasExtraOrderBy
or hasExplicitOrderBy
or (defaultOrderingEnabled and hasMetaOrdering and not hasGroupBy)
```

## Formal Artifacts

- `fvk/mini-queryset-ordered.k`
- `fvk/queryset-ordered-spec.k`

Exact commands to run later, not executed here:

```sh
kompile fvk/mini-queryset-ordered.k --backend haskell
kast --backend haskell fvk/queryset-ordered-spec.k
kprove fvk/queryset-ordered-spec.k
```

Expected machine-check result after any required local K path setup:
`kprove` returns `#Top`.

## Proof Sketch

1. Case `isEmpty = true`: `ordered()` returns `true` immediately. This matches
   the preserved public property behavior and the formal `compilerOrdered`
   model's empty-queryset case. This discharges PO-2.

2. Case `hasExtraOrderBy = true`: `ordered()` returns `true` before consulting
   default ordering or grouping. The compiler uses `extra_order_by` as an
   explicit ordering source. This discharges the extra-ordering part of PO-3.

3. Case `hasExplicitOrderBy = true`: `ordered()` returns `true` before
   consulting default ordering or grouping. The compiler uses explicit
   `query.order_by` before model `Meta.ordering`, and the grouping suppression
   branch drops only `_meta_ordering`. This discharges the explicit-ordering
   part of PO-3, including grouped queries.

4. Remaining cases have no explicit ordering source. V1 returns
   `defaultOrderingEnabled and hasMetaOrdering and not hasGroupBy`. The compiler
   can select `Meta.ordering` only in this same no-explicit-ordering region, and
   `as_sql()` suppresses that source when grouping is active. Therefore the V1
   expression equals the compiler-derived expression. This discharges PO-1,
   PO-4, PO-5, and PO-6.

5. The concrete issue state is:

   ```text
   qs(false, false, false, true, true, true)
   ```

   Substitution into the V1 expression gives
   `true and true and not true`, which reduces to `false`. This is the
   `GROUPED-META-UNORDERED` claim and discharges F1.

6. Source inspection confirms the property remains read-only and public API
   compatible. This discharges PO-7.

## Residual Risk

The proof uses a reduced six-boolean model rather than full Python and full
Django ORM semantics. The abstraction is adequate for the audited branch because
it preserves the exact condition variables used by `QuerySet.ordered` and the
compiler's relevant default-ordering suppression rule. Full-language verification
would still be stronger.

The proof is not machine-checked. The emitted `kompile`, `kast`, and `kprove`
commands must run successfully before any test-redundancy claim is treated as
machine-verified.

## Test Recommendation

Do not remove tests. If tests were being added outside this benchmark's
no-test-editing constraint, the important cases would be:

- grouped aggregate queryset with model `Meta.ordering` and no explicit
  ordering reports `ordered == False`;
- the same grouped queryset with explicit `order_by()` reports `True`;
- non-grouped default model ordering still reports `True`;
- cleared ordering still reports `False`.

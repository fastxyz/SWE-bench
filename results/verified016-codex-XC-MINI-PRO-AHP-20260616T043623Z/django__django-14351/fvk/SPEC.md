# FVK Spec for django__django-14351

Status: constructed, not machine-checked.

## Scope

The verified unit is the V1 change in `repo/django/db/models/sql/query.py`:
`Query.get_group_by_cols()`, plus the existing group-by collection pipeline that
calls it through `Lookup.get_group_by_cols()`, `WhereNode.get_group_by_cols()`,
and `SQLCompiler.get_group_by()`.

There are no loops in the changed unit, so the formal obligations are direct
reachability claims, not circularities.

## Intent Spec

I-001. A queryset RHS used by a related `__in` lookup must render as a
single-column SQL subquery for the `IN` predicate.

I-002. When that lookup is moved into `HAVING` by an `OR` with an aggregate
predicate, group-by collection must not add the raw RHS subquery as a grouped
expression when the RHS query has no outer-column dependencies.

I-003. The fix must preserve the purpose of group-by dependency collection for
correlated subqueries: scalar external column dependencies remain visible, and
Django's existing conservative fallback for possibly multivalued external
columns remains intact.

I-004. The fix must not change public API signatures, callsites, or test files.

## Public Evidence Ledger

E-001. Source: prompt. Quote: "`agent__property_groups__in` gets all fields,
which later results in a `subquery must return only one column` error."
Obligation: prevent default-column RHS subqueries from appearing in `GROUP BY`.
Status: encoded by PO-002 and PO-007.

E-002. Source: prompt. Quote: "`agent__property_groups__id__in` only uses 1"
and is the working form. Obligation: the fixed `agent__property_groups__in`
path must not require callers to spell the target id manually. Status: encoded
by PO-002 and PO-007.

E-003. Source: prompt. Quote: generated SQL shows `HAVING
(T5."property_group_id" IN (SELECT U0."id" ...))` but `GROUP BY` also contains
`(SELECT U0."id", U0."created", ...)`. Obligation: keep the valid `HAVING`
predicate shape while removing the invalid `GROUP BY` RHS subquery. Status:
encoded by PO-007.

E-004. Source: source code. `Subquery.get_group_by_cols()` returns `Ref(alias,
self)` for explicit aliases, otherwise returns `get_external_cols()` except for
the possibly-multivalued fallback. Obligation: raw `Query` expressions used as
lookup RHS subqueries should follow the same grouping dependency contract.
Status: encoded by PO-003, PO-004, and PO-005.

E-005. Source: source code. `Lookup.get_group_by_cols()` appends RHS
`get_group_by_cols()` to LHS group-by columns, and `WhereNode.get_group_by_cols()`
aggregates children. Obligation: for the reported non-correlated RHS query,
`Query.get_group_by_cols()` must return `[]` so the RHS query is not grouped.
Status: encoded by PO-007.

## Formal Spec English

The K artifact `fvk/mini-orm-query.k` abstracts the changed function over three
inputs:

- `Alias`: either no explicit group-by alias or an explicit alias.
- `ExternalCols`: the sequence returned by `Query.get_external_cols()`.
- `HasMulti`: whether any external column is possibly multivalued.

The K claims in `fvk/query-group-by-spec.k` state:

C-001. `getGroupByCols(none, .Exprs, false)` reaches `.Exprs`.

C-002. `getGroupByCols(none, extCol(1, false) ; .Exprs, false)` reaches the
same external column sequence.

C-003. `getGroupByCols(none, extCol(1, true) ; .Exprs, true)` reaches
`selfQuery ; .Exprs`.

C-004. `getGroupByCols(alias(A), CS, HAS_MULTI)` reaches `ref(alias(A)) ;
.Exprs`.

## Spec Audit

C-001 passes against I-002 and E-001/E-003/E-005. It directly distinguishes the
passing fixed behavior from the pre-fix failing behavior: the passing abstraction
returns `.Exprs`; the failing abstraction would return `selfQuery ; .Exprs`.

C-002 passes against I-003 and E-004. It preserves scalar correlated subquery
dependencies.

C-003 passes against I-003 and E-004. It preserves the existing conservative
possibly-multivalued fallback rather than silently weakening correlation
grouping.

C-004 passes against I-003 and E-004. It preserves alias-based grouping behavior
already used by explicit `Subquery`.

No claim is candidate-derived without public or source-contract support. The
pre-fix SQL shown in the issue is treated as SUSPECT legacy behavior and is not
used as expected behavior.

## Public Compatibility Audit

Changed public symbol: `Query.get_group_by_cols(self, alias=None)` is newly
implemented on `Query`, matching the existing expression protocol signature.

Callsites: `SQLCompiler.get_group_by()`, `Lookup.get_group_by_cols()`, and
`WhereNode.get_group_by_cols()` already call `get_group_by_cols(alias=None)` or
without arguments on expression-like objects. The new method accepts the same
optional `alias` parameter used by `Subquery.get_group_by_cols()`.

Subclass/override impact: no public caller is required to pass new arguments,
and no existing method signature was changed. Status: compatible.

## Machine-Check Commands

These commands are recorded only; they were not executed.

```sh
kompile fvk/mini-orm-query.k --backend haskell
kast --backend haskell fvk/query-group-by-spec.k
kprove fvk/query-group-by-spec.k
```

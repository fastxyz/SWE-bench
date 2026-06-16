# FVK Spec

Status: constructed, not machine-checked.

## Scope

This FVK run audits the V1 fix to the order-by contribution in
`SQLCompiler.get_group_by()` for django__django-13569. The verified observable
is whether each non-reference order-by grouping expression is added to the
candidate `GROUP BY` expression list before SQL compilation.

The model intentionally abstracts away SQL rendering, backend-specific function
names, and grouping collapse. Those paths are frame conditions: the issue is
caused before rendering, when `Random()` is admitted into the grouping
expression list.

## Intent Ledger

The public intent ledger is mirrored in `PUBLIC_EVIDENCE_LEDGER.md`.

1. `order_by('?')` must not add `Random()` to grouping because random ordering
   is unrelated to aggregate cardinality.
2. Column-dependent ordering, such as ordering by a related field, must still
   add grouping expressions and may split aggregate rows.
3. Select references remain skipped because select expressions are already
   considered elsewhere.
4. Raw SQL ordering remains included because it is opaque to Django.
5. Subquery grouping expressions with non-empty external columns remain included
   even when the direct expression metadata does not report column references.

## Abstract Contract

For each `(expr, (sql, params, is_ref))` entry in `order_by`:

- If `is_ref` is true, the order-by pass contributes no expressions.
- Otherwise, for each `col` returned by `expr.get_group_by_cols()`:
  - include `col` if `col.contains_column_references` is true;
  - include `col` if any flattened source is `RawSQL`;
  - include `col` if any flattened source exposes non-empty external columns
    through `get_external_cols()`;
  - otherwise skip `col`.

Selected-expression grouping, HAVING grouping, duplicate elimination, and
backend SQL formatting are unchanged frame conditions.

## Formal Core

The formal core is in:

- `fvk/mini-django-groupby.k`
- `fvk/django-groupby-spec.k`

The claims cover:

- `DROP-RANDOM`
- `KEEP-COLUMN`
- `KEEP-RAWSQL`
- `KEEP-EXTERNAL-COLS`
- `DROP-REF`
- the recursive list-filtering step described in `PROOF_OBLIGATIONS.md`

Commands to machine-check later, not executed in this environment:

```sh
cd fvk
kompile mini-django-groupby.k --backend haskell
kast --backend haskell django-groupby-spec.k
kprove django-groupby-spec.k
```

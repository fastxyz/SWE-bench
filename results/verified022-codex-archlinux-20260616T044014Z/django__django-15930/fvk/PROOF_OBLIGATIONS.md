# Proof Obligations

Status: constructed, not machine-checked.

O1. **Full predicate sentinel recognition.**

If a `When` condition is a `WhereNode` that matches everything, the compiled
condition result is `("", [])`. This obligation is supported by the
`WhereNode.as_sql()` contract and is modeled as `Full` in
`mini-django-case.k`.

O2. **Full predicate rendering.**

For `When.as_sql(Full, RESULT, RPARAMS)`, the rendered condition must be
`1=1`, producing `WHEN 1=1 THEN RESULT` and preserving result parameters.
This discharges F1.

O3. **Impossible predicate skip.**

For a one-case `Case` whose `When` condition is impossible, the case is skipped
and the rendered output is the default SQL and default parameters. This
preserves existing `EmptyResultSet` behavior and discharges F2.

O4. **Reported issue case.**

For the issue's boolean branch values, a one-case searched `Case` with a full
condition renders:

`CASE WHEN 1=1 THEN True ELSE False END`

This SQL has a non-empty predicate in the `WHEN` slot and evaluates the `then`
branch for every row under searched-CASE semantics.

O5. **Non-empty predicate preservation.**

For any non-empty condition SQL `C`, `When.as_sql()` renders
`WHEN C THEN RESULT` exactly as before V1.

O6. **Parameter ordering.**

For non-empty predicates, condition parameters precede result parameters. For
the full-predicate sentinel, the condition parameter list is empty by the
`WhereNode.as_sql()` contract, so V1 adds no unmatched placeholders or
parameters.

O7. **Public compatibility.**

The fix must not change `When.as_sql()`'s signature, return type, constructor
behavior, or virtual dispatch shape.

O8. **Honesty gate.**

The constructed proof is not machine-checked. The following commands are the
recorded verification commands and were not executed:

```sh
kompile fvk/mini-django-case.k --backend haskell
kast --backend haskell fvk/django-case-spec.k
kprove fvk/django-case-spec.k
```

# Proof Obligations

Status: constructed, not machine-checked.

## PO-01: Intent adequacy

The formal claims must express the public intent that `.none()` returns no
objects and avoids query execution for ordinary and combined querysets.

Evidence: E1, E2, E3 in `fvk/SPEC.md`.

Discharge: C1 and C2 cover all modeled query shapes, including combined queries.

Finding trace: F-01, F-04.

## PO-02: Empty-state production

`QuerySet.none()` must produce a query state for which `query.is_empty()` is
true.

Evidence: `QuerySet.none()` calls `clone.query.set_empty()`; `Query.is_empty()`
recognizes the `NothingNode` added by `set_empty()`.

Discharge: modeled by `setEmpty(Q) => query(true, ...)`.

Finding trace: F-01.

## PO-03: Empty-state precedence in SQL compilation

If `query.is_empty()` is true, `SQLCompiler.as_sql()` must raise
`EmptyResultSet` before checking combined-query backend support or assembling
SQL from `query.combined_queries`.

Evidence: E1, E2, E3; source location
`repo/django/db/models/sql/compiler.py`.

Discharge: V2 adds the `self.query.is_empty()` guard in `as_sql()` before the
`if combinator:` block. Claim C1 models the same ordering.

Finding trace: F-01, F-02.

## PO-04: No-results execution

`SQLCompiler.execute_sql(MULTI)` must translate `EmptyResultSet` into an empty
iterator without opening a cursor.

Evidence: existing `execute_sql()` catches `EmptyResultSet` before creating a
cursor and returns `iter([])` for `MULTI`.

Discharge: claim C2 models `emptyResult` flowing to `rows(0)` with unchanged
cursor count.

Finding trace: F-01, F-02.

## PO-05: Form empty-value path

For optional `ModelMultipleChoiceField`, empty input must normalize through
`self.queryset.none()` and therefore inherit PO-03 and PO-04.

Evidence: local docs for `ModelMultipleChoiceField`; source
`repo/django/forms/models.py`.

Discharge: claim C3 composes the field empty-value producer with C2.

Finding trace: F-03.

## PO-06: Non-empty combined-query frame condition

The fix must not change non-empty combined queryset behavior.

Evidence: issue only concerns `.none()`; existing compiler has established
support checks and `get_combinator_sql()` behavior for non-empty combined
queries.

Discharge: the V2 guard is conditional on `self.query.is_empty()`. In the model,
non-empty combined queries still reach `unsupported` when backend support is
false and still delegate to `combineSql(...)` when support is true.

Finding trace: F-02.

## PO-07: Public compatibility

The repair must not change public method signatures, form APIs, or queryset
construction APIs.

Evidence: changed source is limited to `SQLCompiler.as_sql()` internals.

Discharge: no public symbol, signature, or virtual dispatch shape changed.

Finding trace: F-04.

## PO-08: Honesty and test policy

Because no tests or K tools may be run, proof artifacts must be labeled
constructed, not machine-checked, and test files must remain unchanged.

Evidence: task constraints and FVK verify honesty gate.

Discharge: all artifacts carry the caveat; no test files were edited.

Finding trace: F-05.

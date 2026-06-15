# FVK Specification for django__django-13158

Status: constructed, not machine-checked. No tests, Python, or K tooling were run.

## Scope

The audited unit is the observable behavior of `QuerySet.none()` when its
underlying `Query` is later compiled or executed by `SQLCompiler.as_sql()` and
`SQLCompiler.execute_sql()`. The issue's user-visible path is
`ModelMultipleChoiceField.clean(empty)` returning `self.queryset.none()` for a
field whose queryset is a `union()`.

The formal model is intentionally smaller than Django. It keeps only the state
needed to distinguish the bug:

- whether the outer `Query` is empty (`query.is_empty()`);
- whether the query has a combinator (`union`, `intersection`, or `difference`);
- whether the backend supports the combinator;
- whether SQL compilation returns normal SQL, raises `EmptyResultSet`, or raises
  `NotSupportedError`;
- whether `execute_sql(MULTI)` opens a cursor or returns an empty iterator.

## Intent Spec

I1. `QuerySet.none()` must create a queryset that never returns model objects.

I2. Accessing a `none()` queryset must not execute a database query.

I3. The empty-query contract applies to combined querysets as well as ordinary
querysets. In particular, calling `.none()` on a `union()` queryset must not
evaluate to the union's original operands.

I4. `ModelMultipleChoiceField` uses `self.queryset.none()` as the empty value for
an optional empty submission, so an empty form submission must normalize to an
empty queryset even when the field queryset is a combined queryset.

I5. The fix must preserve the existing behavior for non-empty combined queries:
unsupported combinators still raise `NotSupportedError`, supported combinators
still compile through `get_combinator_sql()`, and empty child operands are still
handled by the existing combinator logic.

## Public Evidence Ledger

E1. Source: prompt. Quote: "QuerySet.none() on combined queries returns all
results." Obligation: combined-query `.none()` must be empty, not the original
combined result. Status: encoded by claims C1 and C2.

E2. Source: prompt hint. Quote: "`QuerySet.none()` doesn't work properly on
combined querysets, it returns all results instead of an empty queryset."
Obligation: outer empty state must dominate combined SQL assembly. Status:
encoded by C1.

E3. Source: local docs, `repo/docs/ref/models/querysets.txt`. Quote:
"Calling none() will create a queryset that never returns any objects and no
query will be executed when accessing the results." Obligation: `.none()` must
compile through the no-results path and `execute_sql(MULTI)` must not open a
cursor. Status: encoded by C1 and C2.

E4. Source: local docs, `repo/docs/ref/forms/fields.txt`. Quote:
"Empty value: An empty QuerySet (self.queryset.none())." Obligation:
`ModelMultipleChoiceField.clean()` can rely on queryset `.none()` to provide the
empty normalized value. Status: encoded by C3.

E5. Source: implementation, `repo/django/db/models/query.py`. Quote:
`none()` clones the queryset and calls `clone.query.set_empty()`. Obligation:
the compiler must honor `query.is_empty()` for any cloned query shape. Status:
model transition `setEmpty(Q)`.

E6. Source: implementation, `repo/django/db/models/sql/compiler.py`. Quote:
`execute_sql()` catches `EmptyResultSet` and returns `iter([])` for `MULTI`.
Obligation: raising `EmptyResultSet` from SQL compilation is the existing
Django mechanism for "empty queryset, no cursor." Status: encoded by C2.

## Formal Model

The K artifacts are:

- `fvk/mini-django-query.k`: a fragment semantics for query compilation and
  execution results.
- `fvk/django-query-none-spec.k`: claims over that semantics.

The modeled constructors are:

- `query(EMPTY, COMBINATOR, OPERANDS)`;
- `setEmpty(Q)`, representing `Query.set_empty()`;
- `asSql(Q, SUPPORTS_COMBINATOR)`;
- `executeSql(Q, SUPPORTS_COMBINATOR, multi)`.

The model abstracts concrete SQL strings to `sql(N)` where `N` is a symbolic
row source count. This abstraction is property-complete for the defect because
it distinguishes the passing case `emptyResult` from the failing case
`sql(N > 0)`.

## Formal Claims in English

C1. For every query `Q` and every backend support flag `S`,
`asSql(setEmpty(Q), S)` reaches `emptyResult`. This includes the case where `Q`
has a combinator and `S` is false.

C2. For every query `Q` and every backend support flag `S`,
`executeSql(setEmpty(Q), S, multi)` reaches `rows(0)` and leaves cursor count
unchanged.

C3. For every field queryset `Q` and empty optional form value, the normalized
queryset is `setEmpty(Q)`, and by C2 any later multi-result execution reaches
`rows(0)`.

C4. Frame condition: for non-empty combined querysets, the new empty-query guard
does not fire. Unsupported combinators still reach `unsupported`; supported
combinators still delegate to combined SQL assembly.

## Adequacy Audit

C1 vs I1/I2/I3: pass. The claim states that the outer empty marker dominates
both ordinary and combined compilation and does not depend on backend support.

C2 vs I2: pass. The claim states the existing `execute_sql()` no-results
behavior and no cursor creation.

C3 vs I4: pass. The formal model does not need all form validation behavior; it
only captures the documented empty-value producer and delegates emptiness to C2.

C4 vs I5: pass. The claim limits the change to empty queries and preserves
non-empty combined query handling.

No formal claim is derived solely from V1 behavior. V1 is treated as a candidate
implementation, not the specification.

## Public Compatibility Audit

Changed public symbols: none.

Changed method signatures: none.

Virtual dispatch or subclass override surface: none. The change is inside
`SQLCompiler.as_sql()` and adds an early `EmptyResultSet` path for queries that
already report `query.is_empty()`.

Producer/consumer compatibility: preserved. `execute_sql()` already consumes
`EmptyResultSet` as the no-results signal. `QuerySet.none()` already produces
the `query.is_empty()` state via `set_empty()`.

Test files: unchanged by requirement.

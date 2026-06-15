# FVK Spec

Status: constructed, not machine-checked. No tests, Python code, or K tooling were run.

## Target

Audit the V1 fix for `django__django-10880`: `Aggregate.as_sql()` now sets `extra_context['distinct']` to `DISTINCT ` when `self.distinct` is true.

Relevant source:

- `repo/django/db/models/aggregates.py`: `Aggregate.template`, `Aggregate.as_sql()`, `Count.allow_distinct`.
- `repo/django/db/models/expressions.py`: `Func.as_sql()` compiles expressions, joins them, and interpolates `template % data`.

## Intent

The public issue requires a `Count` annotation combining a `Case` expression and `distinct=True` to render valid SQL. The reported bad form is `COUNT(DISTINCTCASE WHEN ...)`; the required property is a separator between the `DISTINCT` token and the following expression.

The intent is token-level SQL rendering correctness. It does not require constructor changes, backend feature changes, result conversion changes, or a new SQL template.

## Domain

Inputs in scope:

- An aggregate SQL template whose distinct marker is placed immediately before the rendered aggregate expression.
- `distinct=True` and `distinct=False`.
- Expressions whose SQL begins with an identifier or keyword, especially `CASE`.
- Conditional aggregation through both native `FILTER` support and the fallback path that rewrites a filter into `CASE`.

Inputs out of scope:

- Database-specific execution semantics after SQL is accepted.
- Quoting and parameter binding of the expression internals.
- Aggregate validation, such as whether a given aggregate class allows `distinct`.

## Public Evidence Ledger

See `fvk/PUBLIC_EVIDENCE_LEDGER.md`. Critical entries:

- E-1: the issue names `Count` plus `Case` plus `distinct=True`.
- E-2: the issue names the missing space in `COUNT(DISTINCTCASE WHEN ...)`.
- E-3: the issue says the error appears whatever the backend.
- E-4 and E-5: source code shows the template concatenates `%(distinct)s%(expressions)s`.
- E-6: source code shows the filter fallback creates a `Case` expression.

## Formal Core

The K fragment is in `fvk/mini-django-aggregate.k`. It models the observable string construction:

- `distinctMarker(true) => "DISTINCT "`.
- `distinctMarker(false) => ""`.
- `aggregateSql(D, F, E) => F + "(" + distinctMarker(D) + E + ")"`.
- `aggregateFilterSql(...)` models the native `FILTER` wrapper.
- `filterFallbackSql(...)` models the filter-to-`CASE` fallback.

The K claims are in `fvk/aggregate-spec.k`.

## Required Claims

Claim C-1: distinct `COUNT` with a `CASE` expression renders `COUNT(DISTINCT CASE WHEN P THEN X ELSE NULL END)`.

Claim C-2: non-distinct `COUNT` with the same expression renders `COUNT(CASE WHEN P THEN X ELSE NULL END)`.

Claim C-3: distinct `COUNT` through the fallback conditional aggregation path renders `COUNT(DISTINCT CASE WHEN P THEN X ELSE NULL END)`.

Claim C-4: distinct `COUNT` through the native SQL `FILTER` path renders `COUNT(DISTINCT X) FILTER (WHERE P)`.

## Adequacy

The model preserves the property under audit because it distinguishes `DISTINCTCASE` from `DISTINCT CASE`. It intentionally abstracts away compiler object identity, params, quoting, and backend execution because those do not affect the reported token adjacency bug.

## Compatibility

See `fvk/PUBLIC_COMPATIBILITY_AUDIT.md`. The V1 fix changes no public signature or return shape and keeps non-distinct rendering unchanged.

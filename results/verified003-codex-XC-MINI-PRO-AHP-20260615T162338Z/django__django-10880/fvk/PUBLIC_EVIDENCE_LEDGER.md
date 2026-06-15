# Public Evidence Ledger

E-1

Source: prompt/problem.

Quoted evidence: "A Count annotation containing both a Case condition and a distinct=True param produces a query error".

Semantic obligation: `Count(Case(...), distinct=True)` must render syntactically valid SQL.

Status: encoded by `aggregate-spec.k` claim 1 and `FINDINGS.md` F-1.

E-2

Source: prompt/problem.

Quoted evidence: "A space is missing at least (... COUNT(DISTINCTCASE WHEN ...)."

Semantic obligation: the `DISTINCT` marker must include a separator before an immediately following expression.

Status: encoded by `aggregate-spec.k` claim 1 and proof obligation PO-1.

E-3

Source: prompt/problem.

Quoted evidence: "whatever the db backend".

Semantic obligation: backend-specific conditional aggregation paths must not reintroduce `DISTINCTCASE`.

Status: encoded by `aggregate-spec.k` claims 3 and 4 and proof obligations PO-4 and PO-5.

E-4

Source: implementation.

Quoted evidence: `Aggregate.template = '%(function)s(%(distinct)s%(expressions)s)'`.

Semantic obligation: because template adjacency is intentional and shared, the separator must be supplied by the `distinct` context value when distinct is enabled.

Status: encoded by proof obligation PO-2.

E-5

Source: implementation.

Quoted evidence: `Func.as_sql()` sets `data['expressions']` to `arg_joiner.join(sql_parts)` and returns `template % data`.

Semantic obligation: aggregate expression SQL is inserted immediately after the distinct marker, so the marker must already contain needed trailing whitespace.

Status: encoded by proof obligation PO-2.

E-6

Source: implementation.

Quoted evidence: `Aggregate.as_sql()` filter fallback builds `Case(condition)` and calls `super(Aggregate, copy).as_sql(..., **extra_context)`.

Semantic obligation: the distinct context value must also be correct when a filter is rewritten into a `CASE` expression.

Status: encoded by proof obligation PO-4.

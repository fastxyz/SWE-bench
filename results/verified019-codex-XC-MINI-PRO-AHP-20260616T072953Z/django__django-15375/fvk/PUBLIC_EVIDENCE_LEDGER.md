# Public Evidence Ledger

## E1: Reported failing call

- Source: prompt
- Evidence: `Book.objects.annotate(idx=F("id")).aggregate(Sum("id", default=0))`
- Obligation: terminal aggregate expressions with `default` must remain valid when subquery aggregation is required by existing annotations.
- Status: encoded in `aggregate-default-spec.k` claim `TERMINAL-DEFAULT-AFTER-ANNOTATE-VALID`.

## E2: Observed invalid SQL shape

- Source: prompt
- Evidence: `SELECT FROM (SELECT ... COALESCE(SUM(...), ?) AS "id__sum" FROM "core_book") subquery`
- Obligation: the terminal aggregate must be moved to the outer aggregate query so the outer `SELECT` is not empty.
- Status: encoded through the `plan(true, ...) => valid` postcondition.

## E3: Explicit `Coalesce` workaround

- Source: prompt
- Evidence: `aggregate(x=Coalesce(Sum("id"), 0))` works.
- Obligation: the internal default wrapper must behave like a terminal aggregate expression when it represents a terminal aggregate.
- Status: encoded as summary preservation by `resolve(true, terminal)`.

## E4: Field independence

- Source: public hint
- Evidence: "The crash happens whether or not the aggregate uses the annotated field."
- Obligation: the fix must not depend on which column the aggregate reads; it must address summary classification of the wrapper.
- Status: encoded by abstracting the aggregate value source away and keeping only the summary/default/subquery flags.

## E5: Candidate location

- Source: public hint
- Evidence: "Aggregate.default generates a Coalesce internally" and the hint points to `django/db/models/aggregates.py`.
- Obligation: repair the wrapper produced in `Aggregate.resolve_expression()`.
- Status: V1 edits only `repo/django/db/models/aggregates.py`.

## E6: Terminal meaning of `summarize`

- Source: source comment/docstring
- Evidence: `BaseExpression.resolve_expression()` documents `summarize` as "a terminal aggregate clause" and sets `c.is_summary = summarize`.
- Obligation: a replacement wrapper returned from `resolve_expression()` should preserve that resolved summary state.
- Status: encoded in `NONTERMINAL-DEFAULT-NOT-SUMMARY` and used to justify keeping V1's `c.is_summary` rather than unconditional `True`.

# Proof Obligations

Status: constructed, not machine-checked.

## PO1 - Detect aggregate references to window annotations

For every resolved aggregate expression in `Query.get_aggregation()`, compute
the set of annotation aliases returned by `aggregate.get_refs()`. If any such
alias names an existing selected annotation with `contains_over_clause`, set
`refs_window`.

Source trace:

- `repo/django/db/models/sql/query.py:419-427`
- Intent ledger I1, I2, I3

Formal claim:

`GET-AGGREGATION-SPEC.window-ref-forces-wrapper`

## PO2 - Window references force the aggregate wrapper

If `refs_window` is true, the aggregate decision must be `Wrapped`, even when no
other wrapper trigger is true.

Source trace:

- `repo/django/db/models/sql/query.py:455-464`
- Finding F1

Formal claim:

`GET-AGGREGATION-SPEC.window-ref-produces-safe-sql-shape`

## PO3 - The wrapper preserves selected annotation refs as outer aliases

When the wrapper path is selected because of `refs_window`, the inner query must
select the referenced annotation alias, and the outer aggregate must keep the
`Ref` rather than inlining the window expression.

Source trace:

- `repo/django/db/models/sql/query.py:493-520`
- `repo/django/db/models/expressions.py:1206`
- Intent ledger I4, I6

Formal claim:

`GET-AGGREGATION-SPEC.window-ref-produces-safe-sql-shape`

## PO4 - Preserve existing wrapper and direct-path behavior

The new condition must not remove existing wrapper triggers, and it must not
force wrapping when all triggers are false.

Source trace:

- `repo/django/db/models/sql/query.py:455-464`
- Intent ledger I5

Formal claims:

- `GET-AGGREGATION-SPEC.existing-trigger-still-wraps`
- `GET-AGGREGATION-SPEC.no-trigger-remains-direct`

## PO5 - Public compatibility

The patch must not change public method signatures, return shapes, expression
interfaces, or virtual dispatch contracts.

Source trace:

- `Query.get_aggregation(self, using, aggregate_exprs)` signature unchanged.
- No public class, method, or expression API changed.

Audit:

`fvk/PUBLIC_COMPATIBILITY_AUDIT.md`

## PO6 - Scope adequacy

The proof must not claim coverage for direct `Aggregate(Window(...))` expression
lifting unless the formal model and source patch actually support it.

Source trace:

- Finding F2
- Baseline notes under "Assumptions and alternatives considered"

Status:

Out of the proven scope. This is not a V1 blocker under the public evidence
available for this task.

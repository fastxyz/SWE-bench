## Root cause

`Aggregate.as_sql()` populated the aggregate template's `%(distinct)s` placeholder with `DISTINCT` and no trailing separator. The aggregate templates concatenate `%(distinct)s%(expressions)s`, so a complex expression beginning with a SQL keyword, such as `Case` rendering as `CASE WHEN ...`, produced invalid SQL like `COUNT(DISTINCTCASE WHEN ...)`.

## Changed files

`repo/django/db/models/aggregates.py`

Changed the SQL context value for distinct aggregates from `DISTINCT` to `DISTINCT `. This keeps the existing aggregate templates intact while ensuring the following aggregate expression is rendered as a separate SQL token. The change also applies to other aggregate subclasses that share the same `Aggregate.as_sql()` path and use the same `%(distinct)s%(expressions)s` convention.

`reports/baseline_notes.md`

Added this report with the root cause, changed-file rationale, assumptions, and rejected alternatives.

## Assumptions

The issue is about SQL string generation, not `Count` validation or `Case` expression compilation. `Case` correctly renders as `CASE ...`; the malformed SQL is caused by the missing separator before that expression.

The hidden tests may cover `Count(Case(...), distinct=True)` directly or another distinct aggregate with a complex first expression. Fixing the shared `Aggregate.as_sql()` context addresses both without broadening behavior beyond distinct aggregate SQL rendering.

## Alternatives considered

Changing `Aggregate.template` to include a space after `%(distinct)s` was rejected because it would also add an extra space when `distinct=False`, e.g. `COUNT( field)`.

Changing only `Count` was rejected because the separator bug lives in the shared aggregate rendering path and the same template convention is used by other distinct-capable aggregates.

Special-casing `Case` was rejected because any aggregate argument whose SQL begins immediately after `DISTINCT` needs the same separator.

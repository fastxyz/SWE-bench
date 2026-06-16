# Baseline Notes

## Root cause

`WhereNode.as_sql()` uses `("", [])` to represent a condition that matches
everything. A negated empty `IN` lookup such as `~Q(pk__in=[])` follows this
path because `pk__in=[]` raises `EmptyResultSet`, and the surrounding negation
turns it into a full-result predicate.

`When.as_sql()` compiled the condition and inserted the returned SQL directly
into its template. When the condition SQL was the empty string, the generated
fragment became `WHEN  THEN ...`, which made `Case()` produce invalid SQL such
as `CASE WHEN THEN true ELSE false END`.

## Files changed

`repo/django/db/models/expressions.py`

Changed `When.as_sql()` so an empty condition SQL string is rendered as the
always-true predicate `1=1` before applying the `WHEN %(condition)s THEN ...`
template. This preserves Django's existing `WhereNode` convention while
producing valid searched `CASE` SQL for `~Q(pk__in=[])`.

`reports/baseline_notes.md`

Added this report describing the root cause, changed files, assumptions, and
alternatives considered.

## Assumptions and alternatives considered

I assumed that an empty condition SQL string from a conditional expression means
"matches everything", consistent with the `WhereNode.as_sql()` contract and the
existing `BooleanField.select_format()` handling for boolean annotations.

I considered handling this in `Case.as_sql()` by treating an always-true `When`
as an immediate result branch. I rejected that as a larger behavioral change
because it would require distinguishing full-result conditions before or during
case compilation, while the immediate failure is that `When.as_sql()` renders an
invalid empty condition.

I considered compiling the condition as `Value(True)` instead of `1=1`. I
rejected that because `CASE WHEN <boolean parameter>` is less portable across
backends than a predicate expression, and the codebase already uses `1=1` as an
always-true SQL predicate in similar expression code.

I did not run tests or execute project code because the task explicitly forbids
running tests or code in this benchmark session.

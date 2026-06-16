# Intent Spec

Status: constructed from public evidence before relying on candidate behavior.

1. `Case(When(~Q(pk__in=[]), then=Value(True)), default=Value(False))` must not
   generate invalid SQL with an empty `WHEN` condition.

2. `~Q(pk__in=[])` is an always-true/full-result predicate. In a searched
   `CASE`, it must select the `then` branch for every row.

3. Empty/impossible predicates such as `Q(pk__in=[])` remain false and should
   continue to fall through to the `Case` default.

4. Non-empty conditional SQL rendered by `When.as_sql()` must preserve its SQL
   text and parameter ordering.

5. The fix should be source-compatible: no public constructor, method
   signature, return shape, or test file should change.

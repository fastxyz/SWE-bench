# Formal Spec English

The K claims in `django-case-spec.k` say the following.

1. **Full-condition case claim.** For a one-branch `Case` whose `When`
   condition is the `WhereNode` full-result sentinel, whose result SQL is
   `True`, and whose default SQL is `False`, rendering reaches:
   `CASE WHEN 1=1 THEN True ELSE False END` with no parameters.

2. **Non-empty predicate preservation claim.** For a `When` whose compiled
   condition SQL is non-empty, rendering reaches the normal template
   `WHEN <condition> THEN <result>` and preserves condition parameters before
   result parameters.

3. **Empty/impossible predicate claim.** For a one-branch `Case` whose `When`
   condition is impossible/empty, rendering reaches the default SQL and default
   parameters, modeling `Case.as_sql()` skipping the impossible case.

The proof scope is partial correctness of this compiler fragment: if the
abstract compiler inputs satisfy the stated condition categories, the rendered
SQL fragment has the specified form. Termination, database execution, and the
full Django ORM are outside the K fragment and remain covered by ordinary tests.

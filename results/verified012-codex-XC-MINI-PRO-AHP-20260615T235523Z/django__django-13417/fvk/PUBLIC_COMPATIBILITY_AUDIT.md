# Public Compatibility Audit

Changed public symbol: `django.db.models.query.QuerySet.ordered`.

Compatibility result: pass.

Evidence:

- The symbol remains a `@property` and still takes no arguments.
- The return type remains boolean.
- Source callsites under `repo/django` read it as a property in
  `django/test/testcases.py`, `django/forms/models.py`, and methods in
  `django/db/models/query.py`; no callsite signature adjustment is required.
- No source override of `QuerySet.ordered` was found under `repo/django`.

The behavior change is intentionally limited to the stale introspection case
where default `Meta.ordering` is suppressed by `GROUP BY` SQL generation.

# Baseline Notes

## Root cause

`Query.check_filterable()` treated every value passed into a filter clause as a
possible ORM expression by reading its `filterable` attribute directly. Ordinary
model instances used as lookup right-hand side values can also have an
application field named `filterable`. When that field is `False`, Django raised
`NotSupportedError` even though the object was valid lookup data, not an
expression that should be rejected from a `WHERE` clause.

## Changed files

`repo/django/db/models/sql/query.py`

The `filterable` guard now applies only to objects that expose
`resolve_expression`, matching Django's expression protocol. This preserves the
existing rejection of real non-filterable expressions such as window
expressions, while allowing ordinary RHS values, including model instances with
a `filterable` field, to pass through normal lookup validation.

## Assumptions and alternatives considered

I assumed `resolve_expression` is the intended discriminator for ORM expression
objects because the surrounding query-building code already uses it before
resolving lookup values and conditional filter expressions.

I considered renaming or special-casing model fields named `filterable`, but
that would treat a valid application model field name as reserved API surface.
The issue is in the internal filterability check, not in user model naming.

I also considered removing the `filterable` check entirely for RHS values, but
that would allow real expression types marked `filterable = False` to be used in
filters. Narrowing the check to expression-like objects fixes the collision
without relaxing expression validation.

No tests were run because this benchmark explicitly forbids executing code.

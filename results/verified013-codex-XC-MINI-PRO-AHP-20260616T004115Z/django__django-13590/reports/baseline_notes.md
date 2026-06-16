# Baseline Notes

## Root cause

`Query.resolve_lookup_value()` recursively resolves expression values inside
list and tuple lookup arguments, then reconstructs the original container type
with a single iterable argument. That works for `list` and plain `tuple`, but it
breaks named tuple instances because their generated constructor expects one
positional argument per field. Passing the generator as the only argument raises
`TypeError` for a two-field named tuple used as a `__range` value.

## Changed files

`repo/django/db/models/sql/query.py`

- Reused the existing generator of recursively resolved lookup values.
- Added a named tuple-specific reconstruction branch for tuple instances with
  `_fields`, unpacking the resolved values into the named tuple constructor.
- Left list, plain tuple, and other tuple subclass reconstruction on the
  existing single-iterable constructor path.

## Assumptions and alternatives considered

- Assumed Django should continue preserving the concrete container type when
  resolving lookup values, matching the existing behavior.
- Treated the `_fields` attribute on tuple instances as the local named tuple
  marker, which covers standard `collections.namedtuple` and `typing.NamedTuple`
  values without importing additional helpers.
- Considered unpacking values for all tuple subclasses, but rejected it because
  plain `tuple` and many tuple-like classes accept a single iterable rather than
  multiple positional values.
- Considered using the named tuple `_make()` helper, but rejected it because the
  issue describes the constructor call as the failing behavior and unpacking into
  the constructor is the smallest targeted adjustment.

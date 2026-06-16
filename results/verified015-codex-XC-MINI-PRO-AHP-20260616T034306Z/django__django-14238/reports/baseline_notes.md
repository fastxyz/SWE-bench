# Baseline Notes

## Root Cause

`Options._get_default_pk_class()` validates `DEFAULT_AUTO_FIELD` with
`issubclass(pk_class, AutoField)`. `AutoField` uses `AutoFieldMeta` to preserve
compatibility by treating `BigAutoField` and `SmallAutoField` as subclasses of
`AutoField`, even though they do not inherit from `AutoField` directly.

`AutoFieldMeta.__subclasscheck__()` only checked exact membership in
`(BigAutoField, SmallAutoField)`. As a result, the concrete Django classes were
accepted, but user-defined subclasses such as `MyBigAutoField(BigAutoField)`
failed the `DEFAULT_AUTO_FIELD` validation.

## Changed Files

`repo/django/db/models/fields/__init__.py`

Changed `AutoFieldMeta.__subclasscheck__()` to use `issubclass(subclass,
self._subclasses)` instead of exact tuple membership. This keeps the existing
compatibility behavior for `BigAutoField` and `SmallAutoField` while extending
it to their subclasses.

## Assumptions and Alternatives

I assumed custom subclasses of `BigAutoField` and `SmallAutoField` should be
valid anywhere Django treats those concrete classes as `AutoField` subclasses,
matching the issue description and the existing `__instancecheck__()` behavior.

I considered changing `Options._get_default_pk_class()` to accept subclasses of
`BigAutoField` and `SmallAutoField` directly, but rejected that because it would
fix only `DEFAULT_AUTO_FIELD` validation and leave other `issubclass(...,
AutoField)` compatibility checks inconsistent.

I also considered changing the `_subclasses` property itself, but it already
identifies the intended compatibility roots. The bug was that
`__subclasscheck__()` used exact membership rather than asking whether the
candidate class inherits from one of those roots.

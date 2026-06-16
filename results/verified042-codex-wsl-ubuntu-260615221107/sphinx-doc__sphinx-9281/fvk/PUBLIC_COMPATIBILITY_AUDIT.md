# Public Compatibility Audit

Status: constructed, not machine-checked.

Changed public callable signatures: none.

Changed public return types: none. `object_description()` still returns `str`
or raises `ValueError` from the existing repr exception path.

Changed dispatch protocols or subclass override contracts: none.

Changed public storage formats: none.

Callsite impact: callers of `object_description()` receive the same type. For
named enum members, the string value intentionally changes to the public
expected member-reference form. Non-enum paths are framed unchanged.

Test files modified: none.

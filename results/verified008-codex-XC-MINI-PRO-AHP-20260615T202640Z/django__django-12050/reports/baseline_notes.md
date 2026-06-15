# Baseline Notes

## Root cause

`Query.resolve_lookup_value()` resolves expression elements inside top-level
`list` and `tuple` lookup values before the lookup is built. After resolving
those elements, it always rebuilt the iterable with `tuple(resolved_values)`.
That changed a direct list lookup value into a tuple before field preparation,
so fields whose serialized or prepared value depends on the original Python
type, such as pickled values, received the wrong type for exact matches.

## Changed files

`repo/django/db/models/sql/query.py`

The iterable rebuild in `Query.resolve_lookup_value()` now preserves whether
the caller supplied a list or tuple. Tuple inputs are still rebuilt as tuples,
and list inputs remain lists after any expression elements are resolved.

## Assumptions and alternatives considered

I assumed the intended behavior is limited to preserving the existing supported
top-level iterable categories handled by this method: `list` and `tuple`.
The issue specifically describes lists being coerced to tuples, and the method
does not attempt to resolve arbitrary iterables.

I considered moving the fix into lookup preparation, but rejected that because
the type change has already happened by the time the lookup object receives the
right-hand side value. Fixing the reconstruction at the source keeps the change
targeted and preserves the existing expression-resolution behavior.

I also considered reconstructing with `type(value)(resolved_values)`, but kept
the explicit list/tuple behavior to avoid changing semantics for tuple
subclasses beyond the existing supported distinction.

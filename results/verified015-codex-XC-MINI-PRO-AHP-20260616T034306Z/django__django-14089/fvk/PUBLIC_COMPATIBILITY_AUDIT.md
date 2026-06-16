# Public Compatibility Audit

Changed public symbol: `django.utils.datastructures.OrderedSet.__reversed__`.

Compatibility result: pass.

Adding `__reversed__()` does not change the constructor, existing methods,
method signatures, return types of existing methods, or storage format.
Existing call sites that iterate, add, remove, discard, test membership, or
measure length continue to use the same API surface.

The new method is a Python data-model hook consumed by the built-in
`reversed()` function. No public subclass override or virtual dispatch call in
the audited source is made incompatible by adding the hook.

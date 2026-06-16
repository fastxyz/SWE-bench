# FVK Notes

## Decisions

V2 keeps the V1 module+qualname resolution because F1 and PO2 show it directly
addresses the reported decorated-method failure: `functools.wraps()` preserves
`__module__` and `__qualname__`, while wrapper globals may belong to the
decorator module.

V2 adds `_get_class_from_qualname()` because F3 and PO5 identified a
compatibility risk in V1: replacing the old top-level `obj.__globals__` lookup
with module lookup only could regress direct top-level cases where the old
lookup worked. The helper first uses module+qualname resolution, then falls
back to `obj.__globals__[cls_path]` only for non-dotted class paths.

V2 imports `unwrap` and checks `unwrap(cls)` because F2 and PO4 identified an
undischarged public hint: class decorators can expose the original class through
the standard `__wrapped__` convention, and V1 only checked the wrapper class's
own `__dict__`.

V2 leaves the rest of `_skip_member()` unchanged because F4 and PO1/PO6/PO7/PO8
confirm the existing gates are part of the intended behavior: docstring
presence, `__weakref__` exclusion, include-with-doc settings, module behavior,
and no-owner fallback to autodoc's default decision.

## Verification Status

The FVK proof artifacts are constructed, not machine-checked. No tests, Python,
or K commands were run. PO10 remains a deliberate integration boundary for real
Python import, descriptor, and wrapper semantics, so the proof justifies the V2
source changes but not removal of tests.

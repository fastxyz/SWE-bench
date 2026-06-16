# Baseline Notes

## Root cause

Napoleon's `_skip_member()` tries to decide whether a private, special, or
`__init__` member with a docstring belongs to the documented class before it
overrides autodoc's default skip decision. For top-level classes it resolved
the owning class with `obj.__globals__[cls_path]`.

That is fragile for decorated methods. A wrapper produced with
`functools.wraps()` preserves `__doc__`, `__module__`, and `__qualname__`, but
the wrapper function's `__globals__` is still the decorator's defining module.
If the decorator lives outside the documented class's module, that globals dict
does not contain the class name, so `_skip_member()` leaves `cls_is_owner` false
and Napoleon does not force documented `__init__` members to be included.

## Changed files

`repo/sphinx/ext/napoleon/__init__.py`

Changed `_skip_member()` so class ownership is resolved from the documented
object's `__module__` and dotted `__qualname__` path for both top-level and
nested classes. This reuses the approach that was already used for nested class
paths and avoids depending on a decorated wrapper's globals.

`reports/baseline_notes.md`

Added the required explanation of the root cause, the source file changed, and
the assumptions considered while making the fix.

## Assumptions and alternatives considered

I assumed the intended behavior is that a documented member whose wrapper keeps
the original member metadata via `functools.wraps()` should be treated like the
original member for Napoleon's include-with-doc settings.

I considered unwrapping the callable via Sphinx's inspect helpers before using
`__globals__`. That would address simple method decorators, but it would keep
two separate owner-resolution paths and would not help cases where resolving
through the module binding is the more accurate view of a decorated class.

I also considered adding a fallback to the old `__globals__` lookup. The module
and qualname lookup should cover normal autodoc-visible classes, including the
nested-class case already handled this way, so retaining the wrapper-globals
path would mainly preserve the brittle behavior that caused this issue.

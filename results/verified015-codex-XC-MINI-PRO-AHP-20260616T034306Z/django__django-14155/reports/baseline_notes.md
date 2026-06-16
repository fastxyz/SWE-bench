# Baseline Notes

## Root cause

`ResolverMatch.__init__()` built `_func_path` directly from the callback object passed by the URL pattern. For `functools.partial` instances, that object doesn't expose the wrapped view function through `__name__`, so Django treated it like a callable object and recorded `functools.partial` as the function path. `ResolverMatch.__repr__()` also printed only the URL-resolved `args` and `kwargs`, so pre-bound partial arguments were hidden.

## Files changed

`repo/django/urls/resolvers.py`

`ResolverMatch.__init__()` now unwraps `functools.partial` callbacks for display metadata. It records the underlying view path and computes repr-only argument and keyword dictionaries that include the partial's pre-bound values. The public `func`, `args`, and `kwargs` attributes are left as originally resolved so request dispatch and legacy tuple unpacking keep the same behavior.

## Assumptions and alternatives considered

I assumed the issue is about the debugging representation and the derived view path, not changing how resolved callbacks are invoked. `BaseHandler.resolve_request()` unpacks `ResolverMatch` and uses `func`, `args`, and `kwargs` to call the view, so replacing `func` with the wrapped function or mutating `args`/`kwargs` would risk changing runtime behavior for existing URL patterns.

I considered changing `__repr__()` alone, but computing the unwrapped path in `__init__()` matches the existing `_func_path` flow and also improves unnamed partial view names. I also handled nested partials so their arguments are reported in the same order they would be applied.

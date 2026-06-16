Root cause:

`method_decorator()` builds a per-instance callable with `functools.partial()` so
decorators can attach attributes to it before the original bound method is
called. That partial object is callable but doesn't start with normal function
metadata such as `__name__`, `__module__`, `__qualname__`, `__doc__`, or
`__annotations__`. Decorators that use or preserve the wrapped callable's
metadata can therefore receive a callable that doesn't look like the original
method, and decorators that inspect `func.__name__` can fail with
`AttributeError`.

Changed files:

`repo/django/utils/decorators.py`

Copied the original method's wrapper metadata onto the partial bound method
before applying user decorators in `_multi_decorate()`. This preserves the
existing reason for using a partial, while ensuring decorators receive a
callable with the usual function wrapper assignments from the original method.

Assumptions and alternatives:

I assumed the bug is specifically the metadata visible to decorators at call
time, not the metadata already copied onto the final method wrapper returned by
`method_decorator()`. The existing `_update_method_wrapper()` and final
`update_wrapper(_wrapper, method)` calls already handle attributes on the
decorated method object itself.

I considered replacing the partial with a nested function that calls the bound
method, but that would be a larger behavioral change and could alter attribute
handling for decorators that mutate the callable they receive. Keeping the
partial and applying `wraps(method)` is the minimal fix because `wraps()` is
already imported and uses the standard wrapper assignment/update behavior.

I also considered changing `_update_method_wrapper()`, but that helper only
copies attributes from decorators onto the outer wrapper and doesn't affect the
callable passed to decorators inside `_multi_decorate()`, where the reported
failure occurs.

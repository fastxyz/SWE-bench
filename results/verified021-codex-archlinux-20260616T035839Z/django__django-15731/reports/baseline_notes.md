# Baseline Notes

## Root cause

`BaseManager._get_queryset_methods()` dynamically creates manager proxy methods for
eligible `QuerySet` methods. The generated proxy accepts `*args` and `**kwargs`,
then forwards the call to the queryset method. It previously copied only
`__name__` and `__doc__` from the original method, so introspection tools such as
`inspect.signature()` saw the proxy function's generic signature instead of the
queryset method's real signature.

Using `functools.wraps()` preserves the original method metadata, including
`__wrapped__`, which lets `inspect.signature()` follow the wrapper and report the
queryset method signature on manager methods.

## Changed files

- `repo/django/db/models/manager.py`: imported `wraps` and applied it to the
  generated `manager_method` inside `_get_queryset_methods()`. Removed the
  manual `__name__` and `__doc__` assignments because `wraps()` handles those
  fields and the additional metadata needed by signature inspection.

## Assumptions and alternatives considered

- Assumed the issue applies to all queryset methods copied onto managers, not
  only `bulk_create()`, because they all share the same proxy-generation path.
- Considered setting `manager_method.__signature__` directly, but rejected it
  because it would duplicate Python's introspection behavior and only address
  signatures rather than preserving the complete wrapper metadata.
- Considered changing individual queryset methods, but rejected that because
  their signatures are already correct; the metadata is lost only when manager
  proxy methods are generated.

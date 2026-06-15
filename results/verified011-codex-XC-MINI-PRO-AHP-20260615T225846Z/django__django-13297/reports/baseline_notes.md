# Baseline Notes

## Root cause

`TemplateView.get()` wrapped URL keyword arguments in `SimpleLazyObject` before
calling `get_context_data()`. That preserved a delayed deprecation warning for
templates, but it changed the values seen by user overrides of
`get_context_data()`. Code that used those kwargs directly, such as filtering a
queryset with a URL slug, received a `SimpleLazyObject` instead of the resolved
string and could pass the unsupported wrapper object down to the database
backend.

## Changed files

`repo/django/views/generic/base.py`

The call to `get_context_data()` now receives the original URL kwargs. After the
context is built, unchanged URL kwargs in the returned context are wrapped with
the existing deprecation-warning `SimpleLazyObject`. This keeps user code in
`get_context_data()` working with the original values while preserving the
warning when `TemplateView` still exposes URL kwargs directly in the rendered
context.

## Assumptions and alternatives

I assumed the compatibility issue is limited to `TemplateView` passing URL
kwargs into `get_context_data()`, because the reported crash happens before
template rendering when user code filters with one of those kwargs.

I also assumed the deprecation warning should remain delayed until the URL kwarg
is accessed from the final context. Emitting the warning before
`get_context_data()` would avoid the lazy wrapper, but it would change the
existing warning timing and could raise earlier under strict warning filters.

I considered changing ORM handling of `SimpleLazyObject`, but the public hint
states that queryset filtering with `SimpleLazyObject` was already unsupported
in earlier versions. The regression is that `TemplateView` started handing
those wrappers to user code, so the fix belongs in the generic view layer.

I considered wrapping every matching context key after `get_context_data()`, but
that could overwrite a value deliberately replaced by an override or
`extra_context`. The implementation only wraps entries that still refer to the
same object originally supplied as a URL kwarg.

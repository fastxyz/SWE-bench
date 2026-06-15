# Public Compatibility Audit

## Changed Public Symbols

None.

## Public Methods Touched Internally

`TemplateView.get(request, *args, **kwargs)` keeps the same signature and return
shape.

`get_context_data(self, **kwargs)` keeps the same virtual dispatch shape. V1
passes original kwargs to this method.

`render_to_response(context)` is called with one context object as before.

## Private Helper

`_wrap_url_kwargs_with_deprecation_warning()` changed from returning a new kwargs
dict to mutating the final context. It is private. Static source search found no
callsite outside `repo/django/views/generic/base.py`.

## Representative Override Scan

`repo/tests/generic_views/views.py`, `repo/django/contrib/auth/views.py`, and
`repo/django/contrib/admindocs/views.py` contain overrides that accept
`**kwargs` and call `super().get_context_data(**kwargs)`. V1 is compatible with
that pattern and improves it by keeping `kwargs` raw before the super call.

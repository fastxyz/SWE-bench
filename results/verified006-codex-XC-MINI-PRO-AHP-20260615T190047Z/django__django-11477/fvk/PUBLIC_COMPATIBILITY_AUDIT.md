# Public Compatibility Audit

Status: constructed, not machine-checked.

Changed symbol:

- `django.urls.resolvers.URLResolver._reverse_with_prefix()`

Compatibility observations:

- Signature is unchanged: `lookup_view`, `_prefix`, `*args`, and `**kwargs` are still accepted exactly as before.
- Public callers remain compatible:
  - `django.urls.base.reverse()` still delegates to `_reverse_with_prefix(view, prefix, *args, **kwargs)`.
  - `django.urls.base.translate_url()` still passes `match.args` and `match.kwargs`.
  - `django.template.defaulttags.URLNode.render()` still calls `reverse()` with resolved template args/kwargs.
- No subclass or override contract was changed; `_reverse_with_prefix()` is an internal resolver method, but it is still callable with the same arguments.
- Error behavior for mixed positional and keyword arguments is preserved because the `ValueError` check still executes before normalization.

Compatibility verdict: no additional source edits required.


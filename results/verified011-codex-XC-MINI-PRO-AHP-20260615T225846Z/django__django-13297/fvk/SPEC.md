# FVK Specification for django__django-13297

Status: constructed, not machine-checked. No tests, Python, `kompile`, or
`kprove` were executed.

## Target

The audited production code is the V1 change in
`repo/django/views/generic/base.py`:

- `TemplateView.get()`
- `_wrap_url_kwargs_with_deprecation_warning()`

The surrounding contract is `ContextMixin.get_context_data()` returning a
template context dictionary from keyword arguments.

## Intent-Only Spec

I1. URL kwargs passed to `TemplateView.get_context_data()` must be the original
URL resolver values, not `SimpleLazyObject` wrappers.

I2. User code inside `get_context_data()` must be able to use a URL kwarg
directly as a normal ORM filter argument, e.g. a slug string.

I3. Django 3.1/3.2 must continue to support passing URL kwargs into the
template context during the deprecation period.

I4. Deprecated direct context access to URL kwargs should still produce the
existing `RemovedInDjango40Warning` when the final context exposes an unchanged
URL kwarg.

I5. Values deliberately changed, removed, or shadowed by an override or
`extra_context` must not be overwritten by the deprecation wrapper pass.

I6. The fix should not change ORM handling of `SimpleLazyObject`; public hints
state that filtering with `SimpleLazyObject` was already unsupported.

## Public Evidence Ledger

E1. Source `benchmark/PROBLEM.md`: "TemplateView.get_context_data()'s kwargs
returns SimpleLazyObjects that causes a crash when filtering."
Obligation: kwargs observed by `get_context_data()` are raw values.

E2. Source `benchmark/PROBLEM.md`: example uses
`offer_slug = kwargs.get("offer_slug", "")` and then
`get_object_or_404(Account, slug=offer_slug)`.
Obligation: the value returned from `kwargs.get()` is directly usable as the URL
converter value.

E3. Source `benchmark/PROBLEM.md`: workaround is `slug=str(offer_slug)`.
Obligation: the need to force a lazy wrapper to `str` is the symptom, not the
intended API.

E4. Source public hint: "`get_object_or_404()` and `QuerySet.filter()` with
`SimpleLazyObject` throw the same exception in Django 2.2 or 3.0."
Obligation: do not redefine ORM `SimpleLazyObject` support as the fix.

E5. Source public hint: "Passing URL kwargs into context is deprecated ... but
should still work in Django 3.1 and 3.2."
Obligation: the final context still exposes URL kwargs for the transitional
period.

E6. Source `repo/docs/releases/3.1.txt`: "The passing of URL kwargs directly to
the context by TemplateView is deprecated. Reference them in the template with
`view.kwargs` instead."
Obligation: preserve the deprecation path and warning semantics.

E7. Source `repo/django/views/generic/base.py`, `ContextMixin` docstring:
"passes the keyword arguments received by get_context_data() as the template
context."
Obligation: the default/super path preserves kwargs into the context.

E8. Source `repo/tests/generic_views/test_base.py`: public deprecation tests
expect `response.context['foo'] == 'bar'` under ignored warnings and a
`RemovedInDjango40Warning` when converting the exposed URL kwarg to `str`.
Obligation: keep delayed warning behavior for direct final context access.

## Formal Model

The constructed mini semantics in `fvk/mini-templateview.k` abstracts the
relevant Python/Django behavior:

- `KW` is the URL kwargs map.
- `C` is the context map returned by `get_context_data(**KW)`.
- `get(KW, C)` records the kwargs argument observed by `get_context_data`, then
  wraps only unchanged URL kwargs in `C`.
- `wrapCtx(C, KW)` updates `C[K]` to `lazy(K, V)` iff `K` is present in `C` and
  `C[K]` is the same value `V` supplied by `KW`.
- Removed or replaced context entries are framed unchanged.

The constructed claims are in `fvk/templateview-spec.k`.

## Adequacy Audit

A1. Claim `GET-FORWARDS-RAW-KWARGS` states that `get_context_data` observes the
same kwargs map `KW` that `TemplateView.get()` receives. This matches I1 and I2.

A2. Claim `GET-RENDERS-WRAPPED-CONTEXT` states that the final response context
is `wrapCtx(C, KW)`. This matches I3 and I4.

A3. Claim `WRAP-UNCHANGED-ENTRY` states that an unchanged context entry derived
from a URL kwarg becomes a lazy warning wrapper. This matches I4 and E8.

A4. Claim `DO-NOT-WRAP-REMOVED-OR-REPLACED` states that missing or replaced
context entries are not reintroduced or overwritten. This matches I5.

A5. No claim changes ORM adaptation of lazy objects. This matches I6.

## Public Compatibility Audit

The public signatures of `TemplateView.get()`, `get_context_data()`, and
`render_to_response()` are unchanged. `_wrap_url_kwargs_with_deprecation_warning`
is private and `rg` found no callsites outside `repo/django/views/generic/base.py`.
Representative public overrides in `django.contrib.auth.views`,
`django.contrib.admindocs.views`, and `tests/generic_views/views.py` keep the
existing `get_context_data(self, **kwargs)` shape and continue to receive raw
kwargs before any context wrapping.

## Machine-Check Commands

These commands are emitted for later reproduction only and were not run:

```sh
kompile fvk/mini-templateview.k --backend haskell
kast --backend haskell fvk/templateview-spec.k
kprove fvk/templateview-spec.k
```

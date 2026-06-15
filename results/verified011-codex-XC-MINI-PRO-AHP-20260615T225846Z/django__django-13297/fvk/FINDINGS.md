# FVK Findings

Status: constructed, not machine-checked. Findings are based on public intent,
static source reading, and proof-obligation construction only.

## F1 - Resolved Code Bug: Lazy URL Kwargs Reached User Overrides

Input: `TemplateView.get(request, **{"offer_slug": "abc"})` with an override
that reads `kwargs["offer_slug"]` and filters on it.

Observed in V0: `get_context_data()` received a `SimpleLazyObject`, so the ORM
filter could receive the wrapper and SQLite could reject it.

Expected from E1-E3: `get_context_data()` receives the original slug value.

V1 status: resolved. `TemplateView.get()` now calls
`self.get_context_data(**kwargs)` before any deprecation wrapper is applied.

Traces to proof obligations: PO1.

## F2 - Confirmed: Deprecated Final Context Access Still Warns

Input: base `TemplateView` or an override that calls `super().get_context_data`
and leaves URL kwarg `foo` unchanged in the returned context.

Expected from E5-E8: final context access to `foo` still works during the
deprecation period and still emits the existing warning when the lazy value is
forced.

V1 status: confirmed. `_wrap_url_kwargs_with_deprecation_warning()` wraps only
context entries whose key is present and whose value is the same object as the
URL kwarg value.

Traces to proof obligations: PO2, PO4.

## F3 - Confirmed: Replaced or Removed Context Entries Are Not Reintroduced

Input: an override removes `foo` from the context or replaces `foo` with a
different object.

Expected from I5: the post-processing wrapper must not overwrite deliberate
context decisions made by overrides or `extra_context`.

V1 status: confirmed. The helper checks `key not in context` before reading and
requires `context[key] is value` before wrapping. This also avoids reintroducing
a missing key whose URL kwarg value is `None`.

Traces to proof obligations: PO3.

## F4 - Confirmed: Public API Compatibility Is Preserved

Input: public subclasses overriding `get_context_data(self, **kwargs)`.

Expected: no new required argument, no changed dispatch shape, no public return
shape change.

V1 status: confirmed. `TemplateView.get()` still calls `get_context_data` with
keyword arguments and still passes the resulting context to
`render_to_response()`. The helper whose signature changed is private and has no
external source callsites in the allowed repository scan.

Traces to proof obligations: PO5.

## F5 - Rejected Alternative: Make ORM Filtering Accept SimpleLazyObject

Input: `QuerySet.filter(slug=SimpleLazyObject(lambda: "abc"))`.

Expected from E4: this is outside the intended fix because it was unsupported in
earlier Django versions too.

V1 status: rejected. The fix remains in `TemplateView`, where the regression was
introduced.

Traces to proof obligations: PO6.

## Proof-Derived Findings From `/verify`

PF1. The constructed proof depends on the Django context contract that
`get_context_data()` returns a mapping supporting membership, lookup, and item
assignment. This is consistent with `ContextMixin` and the surrounding code, but
the mini semantics abstracts away arbitrary non-dict custom returns.
Classification: proof capability boundary, not a code bug for the documented
contract.

PF2. The proof is partial and constructed only. Machine checking was not
performed, and no tests were run. Test removal is not justified.
Classification: honesty gate.

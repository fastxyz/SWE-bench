# Public Evidence Ledger

E1. Problem title: `TemplateView.get_context_data()` kwargs are
`SimpleLazyObject` values and filtering crashes. Obligation: raw kwargs in
`get_context_data()`.

E2. Problem example: `kwargs.get("offer_slug")` is passed to
`get_object_or_404(Account, slug=offer_slug)`. Obligation: direct use in user
code works.

E3. Problem workaround: `str(offer_slug)`. Obligation: forcing the wrapper is a
workaround, not intended.

E4. Public hint: ORM filtering with `SimpleLazyObject` failed in older versions.
Obligation: fix generic view wrapping, not ORM adaptation.

E5. Public hint: passing URL kwargs into context is deprecated but should still
work in Django 3.1 and 3.2. Obligation: final context compatibility.

E6. Release note: use `view.kwargs` instead. Obligation: keep deprecation
warning path.

E7. `ContextMixin` docstring: kwargs received by `get_context_data()` are passed
as template context. Obligation: default/super path carries kwargs into final
context.

E8. Public deprecation tests: context equality works under ignored warnings and
forcing direct context values raises `RemovedInDjango40Warning`. Obligation:
delayed final-context warning.

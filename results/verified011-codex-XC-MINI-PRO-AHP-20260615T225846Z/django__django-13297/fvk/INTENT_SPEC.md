# Intent Spec

Status: intent-only public specification.

1. `TemplateView.get_context_data()` receives raw URL kwarg values.
2. User overrides can use those kwargs directly with ORM filtering.
3. Direct URL kwargs in final template context remain temporarily supported.
4. Final context access to unchanged URL kwargs preserves the existing delayed
   deprecation warning.
5. Overrides or `extra_context` that remove or replace a context key are
   respected.
6. ORM support for manually supplied `SimpleLazyObject` filter values is not in
   scope.

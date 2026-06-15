# Intent Specification

Status: constructed from public evidence only; current code is treated as the candidate under audit.

## Required behavior

1. `translate_url()` must not generate a URL containing a literal `None` when the resolved source URL matched a pattern with an absent optional named group.
2. The correction belongs in `django.urls.resolvers.URLResolver._reverse_with_prefix()`, so direct `reverse()` calls, `translate_url()`, `set_language`, and the `{% url %}` template tag share the same behavior.
3. `None` supplied as a reverse argument means the optional URL component is omitted. This applies to keyword arguments from `resolve()` and to positional arguments supplied directly or through `{% url %}`.
4. Non-`None` falsey values, especially the empty string used for nonexistent template variables, must remain supplied values. They must not be silently discarded.
5. Existing public API shape and core reverse behavior must remain: callers must not mix positional and keyword arguments, URL candidate matching must still reject values that do not satisfy the URL pattern, and no public signature should change.

## Domain

The audited domain is the `_reverse_with_prefix()` argument-normalization and reverse-candidate-selection path for URL patterns whose normalized candidate lists include optional captures. Full regular-expression matching, URL quoting, resolver population, and converter-specific validity remain Django behavior outside the small formal model, but their inputs are constrained by the obligations above.


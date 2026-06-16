# Intent Spec

Status: constructed from public evidence, before accepting candidate behavior as the spec.

## Scope

Target function: `django.contrib.sitemaps.Sitemap.get_latest_lastmod()`.

The audited observable is the value returned to sitemap index generation. The function has no loops and no changed public signature.

## Intent-Derived Obligations

1. If a sitemap has no `lastmod` member, there is no latest last modification value and the method returns `None`.
2. If `lastmod` is a non-callable attribute, `get_latest_lastmod()` returns that attribute value.
3. If `lastmod` is callable and `items()` returns one or more items whose `lastmod(item)` values are mutually comparable date/time values, `get_latest_lastmod()` returns the maximum value over all items.
4. If `lastmod` is callable and `items()` returns no items, the method must not raise `ValueError`; it returns `None`, representing no latest value.
5. The existing `TypeError` recovery remains: if callable `lastmod` values cannot be compared by `max()`, `get_latest_lastmod()` returns `None`.
6. Sitemap index generation treats `None` from `get_latest_lastmod()` as "no lastmod available" and omits the index-level `Last-Modified` contribution for that sitemap.

## Domain Assumptions

- `items()` is finite for the audited call.
- Valid callable `lastmod` values are comparable date/time-like values, as described by the sitemap docs.
- Partial correctness only: this audit does not prove termination of user-provided `items()` or `lastmod()` implementations.

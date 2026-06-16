# FVK Spec

Status: constructed, not machine-checked.

## Target

`Sitemap.get_latest_lastmod()` in `repo/django/contrib/sitemaps/__init__.py`.

The public method returns a latest last-modified value for sitemap index generation. The V1 source patch changes only the callable branch by adding `default=None` to `max()`.

## Public Intent Ledger

This ledger is mirrored in `fvk/PUBLIC_EVIDENCE_LEDGER.md`.

- E1/E2: The reported bug is an empty `items()` result with callable `lastmod`, where pre-fix `max([])` raised `ValueError`.
- E3: Public hint identifies `max(default=...)` as the intended repair mechanism.
- E4: Public docs require the callable non-empty branch to return the latest value over all item `lastmod` values.
- E5: Public docs require the non-callable attribute branch to return the attribute.
- E6/E7: Public docs and public tests support `None` as the "no latest lastmod available" value consumed by sitemap index generation.
- E8: Existing public code and the issue's candidate patch preserve `TypeError -> None`; this is a frame condition, not the main bug.

## Functional Contract

For any `Sitemap` instance in the audited domain:

1. `lastmod` absent: returns `None`.
2. `lastmod` present and not callable: returns `self.lastmod`.
3. `lastmod` callable and `items()` returns an empty finite iterable: returns `None`.
4. `lastmod` callable and all produced values are comparable date/time-like values: returns their maximum.
5. `lastmod` callable and `max()` raises `TypeError` while comparing produced values: returns `None`.

## Frame Conditions

- Public method signature remains `get_latest_lastmod(self)`.
- No new arguments are passed to user overrides, `items()`, or `lastmod(item)`.
- Non-empty comparable callable behavior remains the documented maximum.
- The patch does not catch `ValueError` from user code or from any source other than the empty `max()` condition eliminated by `default=None`.

## Formal Core

- `fvk/mini-python.k` models the relevant Python fragment at the level needed to distinguish the failure: absent/constant/callable `lastmod`, finite callable result lists, `max(..., default=None)`, and `TypeError -> None`.
- `fvk/sitemap-lastmod-spec.k` states reachability claims for the absent, attribute, callable-empty, callable-generic, callable-nonempty-comparable, and callable-type-error cases.

No loop circularity is needed because the audited function has no explicit loop. The list traversal performed by Python's list comprehension and `max()` is represented as recursive spec functions over the finite value list.

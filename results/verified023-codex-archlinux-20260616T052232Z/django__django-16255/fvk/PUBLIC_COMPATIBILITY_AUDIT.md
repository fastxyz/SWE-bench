# Public Compatibility Audit

Status: constructed, not machine-checked.

## Changed Public Symbol

- `django.contrib.sitemaps.Sitemap.get_latest_lastmod(self)`

## Compatibility Checks

| Check | Result | Evidence |
| --- | --- | --- |
| Method signature | Compatible | Signature remains `get_latest_lastmod(self)`. |
| Caller shape | Compatible | `django.contrib.sitemaps.views.index()` still calls `site.get_latest_lastmod()` with no arguments. |
| Override shape | Compatible | Existing overrides can keep the same no-argument signature; the patch does not change virtual dispatch. |
| `items()` dispatch | Compatible | The patch still calls `self.items()` with no arguments. |
| `lastmod()` dispatch | Compatible | The patch still calls `self.lastmod(item)` with exactly one item. |
| Return consumer | Compatible | Sitemap index view already treats `None` as no latest timestamp and omits header contribution. |

## Verdict

No public compatibility problem was found. The patch is behavior-only for the empty callable iterable case and does not alter API shape.

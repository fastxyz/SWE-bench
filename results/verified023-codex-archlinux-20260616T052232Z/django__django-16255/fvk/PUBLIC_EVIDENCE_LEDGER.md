# Public Evidence Ledger

Status: public/user-provided evidence only. Current code is used as implementation evidence, not as the source of expected behavior except where explicitly marked as frame behavior.

| ID | Source | Evidence | Semantic obligation | Status |
| --- | --- | --- | --- | --- |
| E1 | `benchmark/PROBLEM.md` | "Sitemaps without items raise ValueError on callable lastmod." | Empty item collections with callable `lastmod` are in scope and the reported `ValueError` is a bug. | Encoded by O4 / PO-4. |
| E2 | `benchmark/PROBLEM.md` | Trace points to `return max([self.lastmod(item) for item in self.items()])` and `ValueError: max() arg is an empty sequence`. | The failure mechanism is `max()` over an empty sequence. | Encoded by F-001 and the K empty-list claim. |
| E3 | `benchmark/PROBLEM.md` | "The default argument of max() can be used." | Preferred repair is to make the empty iterable case produce a default value rather than masking all `ValueError`s. | Encoded by PO-4 and PO-6. |
| E4 | `repo/docs/ref/contrib/sitemaps.txt` | `get_latest_lastmod()` returns the latest value returned by `lastmod`; if `lastmod` is a method, it is called with all items returned by `items()`. | Callable non-empty case returns the maximum over all item lastmod values. | Encoded by O3 / PO-5. |
| E5 | `repo/docs/ref/contrib/sitemaps.txt` | If `lastmod` is an attribute, its value represents the last-modified date/time for every item. | Non-callable attribute case returns the attribute unchanged. | Encoded by O2 / PO-3. |
| E6 | `repo/docs/ref/contrib/sitemaps.txt` | "If all sitemaps have a `lastmod` returned by `Sitemap.get_latest_lastmod` the sitemap index will have a `Last-Modified` header..." | `None` means a sitemap does not contribute a latest lastmod to the index-level header. | Encoded by O6 / PO-7. |
| E7 | `repo/tests/sitemaps_tests/test_http.py` | Existing public test expects sitemap index `lastmod` to be omitted when `get_latest_lastmod()` returns `None`. | The `None` return path is an established public rendering behavior. | Supporting evidence for O6; no test edits. |
| E8 | implementation/frame | Existing code catches `TypeError` and the issue's suggested patch preserves that catch. | Preserve `TypeError -> None`; do not broaden to catch user-raised `ValueError`. | Encoded by O5 / PO-6. |

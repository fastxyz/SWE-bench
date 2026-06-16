# SPEC AUDIT

Status: constructed, not machine-checked.

| Formal clause | Intent clause | Result | Notes |
| --- | --- | --- | --- |
| `CATCH-REDIRECT-PRESERVES-QUERY` | Intent items 1, 2, and 4 | Pass | Covers the redirect branch and delegates location shape to `fullPathSlash`. |
| `FULL-PATH-NONEMPTY-QUERY` | Intent items 1, 2, and 3 | Pass | Generalizes the public `id=123` example to all non-empty query strings. |
| `FULL-PATH-EMPTY-QUERY` | Intent item 2 and request-helper behavior | Pass | Prevents over-correcting by adding a bare `?` when no query exists. |
| `CATCH-NO-REDIRECT-WHEN-GATES-FAIL` | Intent item 4 | Pass | Keeps the existing non-redirect behavior outside the intended redirect branch. |
| Frame and compatibility conditions | Intent item 5 | Pass | The fix changes only the redirect target expression. |

No clause proves the legacy query-dropping behavior. No clause is marked fail or
ambiguous.

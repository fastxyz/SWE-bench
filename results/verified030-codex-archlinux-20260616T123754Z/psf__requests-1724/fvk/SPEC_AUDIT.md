# Spec Audit

Status: pass for the scoped issue.

| Formal English item | Intent item | Result | Notes |
| - | - | - | - |
| PREPARE-METHOD-PY2-UNICODE | Intent 1, 2 | Pass | This is the exact reported failing shape. |
| PREPARE-METHOD-PY2-NATIVE | Intent 1, 3 | Pass | Preserves the working native-string path. |
| SESSION-REQUEST-PY2-UNICODE | Intent 1, 2, 5 | Pass | Covers the public `requests.request()` path. |
| PREPARE-METHOD-NONE | Public API default behavior | Pass | Existing `prepare_method(None)` behavior is framed, not issue-derived. |
| ASCII-METHOD-SIDE-CONDITION | Intent 4 | Pass | The public issue says unicode object, not non-ASCII HTTP method name. |
| PUBLIC-COMPATIBILITY | Intent 5 | Pass | No signature or call-shape change. |

No item is candidate-derived without public support. The reported
`UnicodeDecodeError` is not treated as expected behavior.


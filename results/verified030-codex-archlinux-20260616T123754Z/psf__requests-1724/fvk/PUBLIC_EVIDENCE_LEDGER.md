# Public Evidence Ledger

| ID | Source | Evidence | Obligation |
| - | - | - | - |
| E-001 | `benchmark/PROBLEM.md` | "`method=u'POST'` ... produces a UnicodeDecodeError" | Treat the traceback as the bug to remove. |
| E-002 | `benchmark/PROBLEM.md` | "`method='POST'` works fine" with the same request otherwise | Unicode and native spellings of `POST` must be equivalent at send time. |
| E-003 | `benchmark/PROBLEM.md` | "`u'POST'` is infecting the header with unicode when it should be a string" | Prepared method must be native string on Python 2. |
| E-004 | `repo/requests/models.py` docstring | `:param method: HTTP method to use.` | Preserve normalized HTTP method semantics. |
| E-005 | `repo/requests/utils.py` | `to_native_string()` returns native string type and assumes ASCII by default. | Use the existing compatibility helper for ASCII method tokens. |
| E-006 | `repo/requests/adapters.py` | `conn.urlopen(method=request.method, ...)` | `PreparedRequest.method` is the method value sent to transport. |
| E-007 | `repo/test_requests.py` | `test_header_keys_are_native` asserts native prepared header keys. | Native type conversion is an existing Requests compatibility pattern. |


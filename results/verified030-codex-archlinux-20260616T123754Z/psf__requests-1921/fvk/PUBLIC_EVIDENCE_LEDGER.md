# Public Evidence Ledger

Status: public evidence only. Current code is used as implementation evidence,
not as the desired contract.

| ID | Source | Evidence | Semantic Obligation | Status |
| --- | --- | --- | --- | --- |
| E1 | `benchmark/PROBLEM.md` | "you can prevent sending a session header by setting the headers value to None in the method's arguments" | Request-level header `None` is a deletion sentinel. | Encoded by PO-1, PO-5, C-REQUEST-NONE. |
| E2 | `benchmark/PROBLEM.md` | "You would expect ... this would work for session's default headers, too" and `session.headers['Accept-Encoding'] = None` | Session-level default header `None` must also delete the header from prepared requests. | Encoded by PO-1, PO-3, C-SESSION-NONE. |
| E3 | `benchmark/PROBLEM.md` | Reported buggy output: `Accept-Encoding: None` | Literal string/serialized value `None` for that header is the legacy bug, not expected behavior. | Finding FVK-F1. |
| E4 | `benchmark/PROBLEM.md` | "Actually, I think this is a bug in how we merge the headers before firing off a request" | The correction belongs in merge semantics before `PreparedRequest.prepare_headers()` serializes headers. | Encoded by PO-2, PO-3. |
| E5 | `repo/test_requests.py` | `test_header_remove_is_case_insensitive` uses `headers={'FOO': None}` and asserts `'foo' not in r.request.headers` | Request-level `None` deletion is case-insensitive in the prepared request. | Encoded by PO-5, C-REQUEST-NONE. |
| E6 | `repo/requests/sessions.py` docstring | `merge_setting()` merges request and session settings, and non-dictionaries bypass the merge. | Preserve request-over-session precedence and non-mapping bypass behavior. | Encoded by PO-2, PO-7, C-NONMAPPING-FRAME. |
| E7 | `repo/requests/structures.py` docstring | `CaseInsensitiveDict` queries and contains testing are case-insensitive. | Header claims may reason over canonical lowercase keys. | Encoded by PO-4, PO-5. |
| E8 | `repo/requests/models.py` | `Request.__init__` converts `headers=None` to `{}` before `Session.prepare_request()`. | The issue path reaches the mapping/mapping branch of `merge_setting()`, even when no per-request headers are supplied. | Encoded by PO-8. |


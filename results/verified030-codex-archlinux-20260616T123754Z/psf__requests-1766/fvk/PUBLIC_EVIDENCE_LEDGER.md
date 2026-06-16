# Public Evidence Ledger

Status: constructed from public evidence; not machine-checked.

| ID | Source | Evidence | Semantic obligation | Status |
| --- | --- | --- | --- | --- |
| E-1 | `benchmark/PROBLEM.md` | "quote qop options in Digest Auth" | The repaired observable is Digest Auth qop formatting. | Encoded by PO-1. |
| E-2 | `benchmark/PROBLEM.md` | "qop-options ... If present, it is a quoted string of one or more tokens" | The qop value is token-list shaped, not only a singleton literal. | Encoded by PO-2. |
| E-3 | `benchmark/PROBLEM.md` | "curl command-line tool also appends these quotes" | The client Authorization header must carry quotes around the selected qop value. | Encoded by PO-1. |
| E-4 | `benchmark/PROBLEM.md` | "some minor server-side implementations seem to be sensitive on this difference" | Header formatting is externally observable and cannot be treated as cosmetic. | Encoded by PO-1 and F-1. |
| E-5 | `repo/requests/auth.py` | `elif 'auth' in ...` / `base += ', qop="auth"...'` after V2 | Requests chooses the supported `auth` qop token when available and serializes it. | Checked by PO-1 and PO-2. |
| E-6 | `repo/requests/auth.py` | `# XXX handle auth-int.` | `auth-int` remains self-declared incomplete in this version. | Recorded as F-3 and excluded from proof success. |
| E-7 | `repo/docs/user/authentication.rst` | `requests.get(url, auth=HTTPDigestAuth('user', 'pass'))` | Public construction and use of `HTTPDigestAuth` must remain compatible. | Checked by PO-5. |
| E-8 | `repo/test_requests.py` | Visible digest tests assert status codes through HTTPDigestAuth, not raw qop formatting. | Tests are integration evidence only; they do not veto the raw header intent. | Reflected in proof/testing notes. |


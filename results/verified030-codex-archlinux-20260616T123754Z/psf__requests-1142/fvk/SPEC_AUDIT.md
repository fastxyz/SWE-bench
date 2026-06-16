# Spec Audit

Status: constructed, not machine-checked.

| Formal item | Intent item | Verdict | Notes |
|---|---|---|---|
| `GET-NO-BODY` | Intent 1 | Pass | Directly encodes the issue request that bodyless/default `GET` not get automatic `Content-Length`. |
| `GET-NONE-DATA` | Intent 5 | Pass | V1 missed this public no-body spelling; V2 normalizes `data=None` to the omitted-data path. |
| `GET-BODY` | Intent 2 | Pass | Supported by public discussion that a `GET` request can carry data. |
| `OTHER-NO-BODY` | Intent 4 | Pass | Keeps non-`GET` behavior unchanged because issue evidence is GET-specific. |
| `GET-EXPLICIT-CL` | Intent 3 | Pass | The issue objects to automatic addition, not user-specified headers. |
| Auth recomputation frame | Intent 1 | Pass | Prevents `prepare_auth` from reintroducing the same automatic header after V2 suppresses it. |
| Empty explicit iterable `data=[]` | Out of scope 2 | Ambiguous | The issue does not decide whether this is "no body" or an explicit zero-length stream. It is not used to justify V2 success. |

No formal item fails against the intent spec after the V2 edit.

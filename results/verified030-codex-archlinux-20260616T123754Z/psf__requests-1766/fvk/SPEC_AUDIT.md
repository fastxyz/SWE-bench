# Spec Audit

Status: constructed, not machine-checked.

| Formal English item | Intent item | Result | Notes |
| --- | --- | --- | --- |
| QOP-AUTH-LIST says qop options containing `auth` produce `qop="auth"`. | I-1, I-2 | Pass | Covers the direct quote requirement and the "one or more tokens" shape. |
| QOP-AUTH-LIST says the digest input qop token is also `auth`. | I-2 | Pass | This is required so the advertised qop and hashed qop are the same selected token. |
| QOP-NO-QOP preserves absence of qop field. | I-3 | Pass | Keeps the no-qop path outside the reported formatting change. |
| QOP-UNSUPPORTED returns unsupported for no-`auth` qop lists. | I-4 | Pass with residual risk | This matches current implementation scope but does not prove full RFC `auth-int`. F-3 records the residual. |
| Frame claim preserves method signature and callsites. | I-5 | Pass | Public construction and dispatch shape are unchanged. |

No formal-English item is candidate-derived without public intent or a named frame condition. The only residual is the already existing `auth-int` incompleteness, which is explicitly excluded from proof success.


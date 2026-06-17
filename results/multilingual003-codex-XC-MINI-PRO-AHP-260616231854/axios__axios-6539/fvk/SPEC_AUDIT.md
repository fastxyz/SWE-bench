# Spec Audit

Status: constructed, not machine-checked.

| Formal item | Intent item | Verdict | Notes |
| --- | --- | --- | --- |
| K-001 | I-001, I-002, E-007 | Pass | The predicate covers the authority-form class that the fallback parser must not reinterpret as `http:`. |
| K-002 | I-001, I-002, E-003, E-004 | Pass | Rejection occurs before the fallback parse in the modeled adapter step. |
| K-003 | I-003 | Pass | The guard does not reject representative ordinary relative paths, preserving the fallback base for those inputs. |
| K-004 | I-004 | Pass | The formal scope is explicit and server-side. |
| CommonJS/source parity | I-005, E-005 | Pass | Both `repo/lib/adapters/http.js` and `repo/dist/node/axios.cjs` carry the same predicate and rejection branch. |

No required behavior is marked fail or ambiguous after the V2 regex change.


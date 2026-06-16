# Spec Audit

Status: constructed, not machine-checked.

| Formal item | Intent coverage | Result |
| --- | --- | --- |
| `resolve(none, true, OLD) => none` | Matches E1-E4 and the `raise ... from None` example. | Pass |
| `resolve(CAUSE, SUPPRESS, CTX) => CAUSE` for `CAUSE != none` | Matches "explicit or implicit cause" precedence and Python exception chaining semantics. | Pass |
| `resolve(none, false, CTX) => CTX` | Matches the implicit-context fallback when no suppression is requested. | Pass |
| `isExplicit(none) => false` | Matches the template flag meaning: no direct cause exists. | Pass |
| `isExplicit(CAUSE) => true` for `CAUSE != none` | Matches the template flag meaning: direct cause exists independent of object truthiness. | Pass |
| Suppressed issue-chain claim records only `exc(1)` | Matches the reported bug's expected behavior: the handled `RuntimeError` is not shown. | Pass |
| Unsuppressed discriminator records `exc(1), exc(0)` | Confirms the abstraction can distinguish passing and failing behavior for the issue property. | Pass |

No formal-English obligation is candidate-only or legacy-derived. The only implementation-derived facts are the names and locations of the helper, loop, and frame metadata keys; those facts determine where to repair the code, not the desired behavior.

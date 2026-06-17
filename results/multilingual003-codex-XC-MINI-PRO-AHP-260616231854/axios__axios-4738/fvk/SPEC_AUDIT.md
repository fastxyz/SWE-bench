# Spec Audit

| Formal item | Intent item | Verdict | Notes |
|---|---|---|---|
| Claim 1 custom branch | Intent 1 | Pass | It states that a truthy configured message is the rejected message. |
| Claim 2 default branch | Intent 2 | Pass | It preserves the previous default when no truthy custom message exists. |
| `chooseCode(CL)` | Intent 3 | Pass | It leaves `clarifyTimeoutError` behavior as an independent code decision. |
| `<aborted> false => true` | Intent 4 | Pass | It preserves the existing abort side effect. |
| Abstract `defaultMsg(T)` instead of concrete string concatenation | Intent 2 | Pass with abstraction | The model distinguishes default from custom; concrete rendering remains documented in SPEC.md and PO-03. |
| Empty-string custom message falls into default branch | Intent 1/2 | Ambiguous but non-blocking | Public issue uses a non-empty string. XHR adapter uses a truthy check, so V1 follows existing public behavior. See F-04. |

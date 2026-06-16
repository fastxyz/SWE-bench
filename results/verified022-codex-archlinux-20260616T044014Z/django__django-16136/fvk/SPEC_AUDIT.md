# Spec Audit

Status: constructed, not machine-checked.

| Formal obligation | Intent obligation | Verdict | Notes |
| --- | --- | --- | --- |
| `ASYNC-NOT-ALLOWED-AWAITABLE` | Async unsupported methods must not return a raw response to an async caller. | Pass | Directly follows `E1`, `E2`, `E3`, `E4`. |
| `ASYNC-NOT-ALLOWED-AWAIT` | Final result for the reported case is a 405 response, not `TypeError`. | Pass | Directly models and removes the issue symptom. |
| `SYNC-NOT-ALLOWED-DIRECT` | Sync behavior remains direct response. | Pass | Required by "both sync and async cases" in `E2` and default docs `E5`. |
| `ALLOW-HEADER-PRESERVED` | `HttpResponseNotAllowed` includes allowed methods. | Pass | Directly follows `E5` and `DA2`. |
| `OPTIONS-PARITY` | Use same adaptation strategy as `options()`. | Pass | Directly follows public hint `E2` and local pattern `E6`. |
| `SUPPORTED-DISPATCH-FRAME` | Do not disturb supported method dispatch. | Pass | Frame condition from minimal patch scope; no public intent requires a dispatch refactor. |
| `PUBLIC-COMPAT-FRAME` | Preserve public override/call compatibility. | Pass | Signature and call shape unchanged. |

No formal obligation is candidate-derived without public evidence. No required
behavior is marked fail or ambiguous.

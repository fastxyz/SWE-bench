# Spec Audit

Status: constructed, not machine-checked.

| Formal claim | Intent match | Audit |
| --- | --- | --- |
| `PARTIAL-REPR` | Pass | Matches E1/E2/E3: repr displays wrapped callable path and bound partial args/kwargs. |
| `NESTED-PARTIAL-REPR` | Pass | Extends the same partial family to a nested partial shape present in public source (E6). |
| `NONPARTIAL-REPR` | Pass | Frame condition: public intent names partials only, so non-partial display behavior is preserved. |
| `FRAME-PUBLIC-TRIPLE` | Pass | Required by docs and dispatch call path (E4/E5/E8). |
| `VIEW-NAME-FRAME` | Pass | Preserves `url_name` precedence and follows the partial display-path obligation when no name is supplied. |

No claim is based solely on V1 behavior. The only implementation-derived domain restriction is resolver-created tuple args (E7), and it is recorded as a domain boundary rather than used to reject issue intent.


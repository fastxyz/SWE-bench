# Spec Adequacy Audit

Status: constructed, not machine-checked.

| Formal claim | Intent coverage | Result |
| --- | --- | --- |
| `CSTACK-SHAPE` | Matches INT-4 and INT-5. | Pass |
| `CSTACK-LEFT-PRESERVE` | Matches block concatenation implied by INT-2, INT-4, INT-5. | Pass |
| `CSTACK-RIGHT-PRESERVE` | Directly captures INT-1 and INT-3; rejects suspect INT-6. | Pass |
| `CSTACK-OFF-BLOCKS` | Captures the issue's stated independence of linear models from projection inputs. | Pass |
| `CSTACK-NESTED-RIGHT` | Captures INT-3, the core nested CompoundModel requirement. | Pass |

No claim preserves the suspect pre-fix all-True bottom-right block. No claim is
derived solely from V1 behavior.

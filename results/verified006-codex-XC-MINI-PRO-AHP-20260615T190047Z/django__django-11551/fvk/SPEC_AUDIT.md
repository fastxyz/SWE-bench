# Spec Audit

Status: constructed, not machine-checked.

| Formal claim | Intent coverage | Audit result |
| --- | --- | --- |
| `CALLABLE_OK` | Intent Spec 1; ledger E4, E7. | Pass |
| `FIELD_REGULAR_OK` | Intent Spec 2, 3; ledger E1, E2, E4. | Pass |
| `FIELD_NONE_OK` | Intent Spec 2 and issue's descriptor-returns-`None` discussion; ledger E2. | Pass |
| `FIELD_M2M_E109` | Intent Spec 5; ledger E3, E5, E7. | Pass |
| `FIELD_M2M_ADMIN_PRECEDENCE_E109` | Intent Spec 6; ledger E5, E6, E8. | Pass |
| `ADMIN_ATTR_OK` | Intent Spec 1; ledger E4, E7. | Pass |
| `MODEL_ATTR_REGULAR_OK` | Intent Spec 1, 4; ledger E2, E4. | Pass |
| `MODEL_ATTR_NONE_OK` | Intent Spec 4 and the issue discussion of descriptors returning `None`. | Pass |
| `MODEL_ATTR_M2M_E109` | Intent Spec 5; ledger E3, E5. | Pass |
| `MISSING_ALL_E108` | Intent Spec 4, 7; ledger E2, E7. | Pass |

The adequacy gate fails for V1 on `FIELD_M2M_ADMIN_PRECEDENCE_E109`; V1 returns
`OK` for that input shape. V2 repairs the mismatch by checking model metadata
before `hasattr(obj, item)`.


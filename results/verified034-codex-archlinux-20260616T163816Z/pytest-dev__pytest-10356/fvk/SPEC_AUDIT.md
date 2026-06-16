# Spec Audit

Status: constructed, not machine-checked.

| Formal English item | Intent item | Result | Notes |
| --- | --- | --- | --- |
| CLAIM-MRO-COMPLETE | Intent 1, 2 | pass | Directly covers the reported `Foo`/`Bar` missing mark. |
| CLAIM-OWN-ONLY-STORE | Intent 2, 3 | pass | Needed to preserve no base/sibling mutation and avoid duplicate inherited marks. |
| CLAIM-NONCLASS-FRAME | Intent 4 | pass | Non-class branch is unchanged. |
| CLAIM-INVALID-FRAME | Intent 5 | pass | Normalization remains centralized. |
| Sibling-base order not claimed | Ambiguity 1 | pass | The spec does not prove an order policy from insufficient evidence. |
| Metaclass descriptor support not claimed | Ambiguity 2 | pass with residual risk | Descriptor behavior is recorded in Finding F4 rather than silently specified. |

Conclusion: the formal claims are adequate for the reported completeness bug.
They are intentionally not adequate to settle marker order or metaclass descriptor
policy.

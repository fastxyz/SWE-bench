# Spec Audit

Status: constructed, not machine-checked.

| Formal claim | Intent match | Result |
| --- | --- | --- |
| `(SERIALIZE-MODELS-MODEL)` | Matches INT-1, INT-2, and INT-4: `models.Model` output must bind `models`. | Pass |
| `(SERIALIZE-NONE-TYPE)` | Matches frame condition INTENT_SPEC item 5. | Pass |
| `(SERIALIZE-CUSTOM-TYPE)` | Matches frame condition INTENT_SPEC item 5 and supports the reported custom mixin. | Pass |
| `(SERIALIZE-REPORTED-BASES)` | Matches INT-2 and INT-3: bases alone can require both imports. | Pass |
| `(RENDER-WITH-MODELS)` | Matches INT-1 and INT-2: migration imports bind names used in the body. | Pass |
| `(RENDER-WITHOUT-MODELS)` | Matches frame condition: do not add `models` when no serializer requested it. | Pass |
| Public compatibility frame | Matches INTENT_SPEC item 6. | Pass |

No formal claim is derived solely from the V1 implementation. The V1 behavior
matches public intent because the issue explicitly identifies missing import
binding as the defect and points to the `models.Model` special case as the
likely source.

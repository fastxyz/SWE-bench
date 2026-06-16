# SPEC AUDIT

Status: constructed, not machine-checked.

| Formal obligation | Intent match | Result |
| --- | --- | --- |
| Exact root-exported deconstructible expressions return `django.db.models.X`. | Matches INTENT_SPEC item 1 and evidence E1-E3. | Pass |
| Args and kwargs are preserved. | Matches INTENT_SPEC item 2 and evidence E4. | Pass |
| Subclasses/internal helpers keep fallback paths. | Matches INTENT_SPEC item 4 and evidence E4. | Pass |
| Serializer renders `models.X` for `django.db.models.X`. | Matches INTENT_SPEC item 3 and evidence E5. | Pass |
| `Subquery`/`Exists` are not newly deconstructible. | Matches INTENT_SPEC item 5 and evidence E6, but remains a future-feature ambiguity if maintainers request query serialization. | Pass with residual ambiguity recorded as F-003 |

No formal obligation contradicts the public issue intent.


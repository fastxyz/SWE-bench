# Proof Obligations

Status: constructed, not machine-checked.

| ID | Obligation | Evidence | Discharge |
| --- | --- | --- | --- |
| PO-1 | Session-level header `None` is a deletion sentinel in the prepared request. | E2, E3, E4 | C-SESSION-NONE and proof step P3. |
| PO-2 | Mapping merge order is session first, request second, with request values winning. | E6 | C-MERGE-MAPPING and P1-P2. |
| PO-3 | Deletion must inspect final merged values, not only request-side values. | E1, E2, E3 | C-MERGE-MAPPING, C-SESSION-NONE, and P3. |
| PO-4 | A non-`None` request value overrides a session `None` value and remains present. | E6 | C-REQUEST-OVERRIDE and P4. |
| PO-5 | Request-level `None` removal remains case-insensitive for headers. | E1, E5, E7 | C-REQUEST-NONE and P5. |
| PO-6 | The merge does not mutate `Session.headers`; deletion occurs on the merged copy. | E6, implementation flow | P2 and P6. |
| PO-7 | Non-mapping settings preserve existing request-wins bypass behavior. | E6 | C-NONMAPPING-FRAME and P7. |
| PO-8 | The issue path reaches the mapping/mapping branch even when the user supplies no per-request headers. | E8 | P8: `Request.__init__` converts `headers=None` to `{}`. |
| PO-9 | The formal abstraction can distinguish the defect. | E2, E3, E7 | Passing case omits canonical key; failing case contains the key with `noneVal`. |

No proof obligation requires changing V1. The only non-blocking ambiguity is the
direct helper edge where `request_setting is None` and `session_setting` is a
mapping containing `None`; that branch is outside the public issue path and is
listed in `FINDINGS.md` as FVK-F3.


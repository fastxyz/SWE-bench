# SPEC_AUDIT

Status: constructed, not machine-checked.

| Formal English item | Intent item | Result | Notes |
| --- | --- | --- | --- |
| `reverse-old-fields-restores-generated-name` | INTENT_SPEC 1, 2 | Pass | Directly encodes the issue and hint. |
| `reverse-old-fields-skipped-when-migration-disallowed` | INTENT_SPEC 5 | Pass | Preserves existing migration routing behavior. |
| `round-trip-reapply-safe` | INTENT_SPEC 3 | Pass | Encodes the reported reapply crash as the failure to avoid. |
| Named-index branch frame condition | INTENT_SPEC scope | Pass | The problem concerns unnamed `old_fields`; named behavior already has a reverse path. |
| Unique constraint handling omitted | INTENT_SPEC ambiguity | Pass with caveat | The omission is deliberate because the public operation state semantics target `index_together`. |

No formal claim is derived solely from V1 behavior. The legacy public no-op test
is marked SUSPECT and is not used as intended behavior.

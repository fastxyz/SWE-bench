# Spec Audit

Status: constructed, not machine-checked.

| Formal claim | Intent comparison | Result |
| --- | --- | --- |
| `deleteShape(0, 0) == direct` | Matches E1-E5. This is the exact reported `Model.objects.all().delete()` case before alias initialization. | Pass |
| `deleteShape(1, 0) == direct` | Matches the public hint's "single alias" wording and preserves the pre-existing direct branch for ordinary single-table filters. | Pass |
| `activeAliases >= 2 -> fallback` | Matches E5: only single-alias deletes are direct; multi-table cases must continue through existing fallback behavior. | Pass |
| `extraTables > 0 -> fallback` | Entailed by E7. `_as_sql()` cannot express additional `FROM` contributors, so treating `extra_tables` as direct would over-broaden the issue fix. | Pass |

No formal claim is derived solely from current candidate output. The direct-delete claims trace to public issue text; the fallback claims trace to the public hint and source-level compatibility constraints.

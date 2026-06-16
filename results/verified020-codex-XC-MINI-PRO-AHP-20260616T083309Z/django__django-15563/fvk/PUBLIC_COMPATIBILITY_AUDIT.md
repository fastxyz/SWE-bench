# Public Compatibility Audit

Status: constructed, not machine-checked.

## Changed symbols

| Symbol | Public? | Compatibility status |
| --- | --- | --- |
| `UpdateQuery.related_ids` | No, private compiler/query coordination state. | Shape changes from one list to a model-keyed dictionary only inside the same private subsystem. |
| `UpdateQuery.clone()` | No public signature change. | Preserves copied private state when present. |
| `UpdateQuery.get_related_updates()` | Internal ORM SQL query method. | Return shape remains a list of `UpdateQuery` objects. Filtering changes only to use model-specific IDs. |
| `SQLUpdateCompiler.pre_sql_setup()` | Internal compiler hook. | Public signature unchanged. Still applies the main `pk__in` filter and preselects IDs when related updates or backend constraints require it. |
| `SQLUpdateCompiler._get_update_related_id_lookup()` | New private helper. | No public compatibility impact. |

## Public API/callsite conclusion

No public API signature, return type, virtual dispatch contract, or test helper
contract is changed. The public behavior change is the intended bug fix:
`QuerySet.update()` on a child model now updates the ancestor rows linked to the
child instances instead of unrelated rows in another parent table.

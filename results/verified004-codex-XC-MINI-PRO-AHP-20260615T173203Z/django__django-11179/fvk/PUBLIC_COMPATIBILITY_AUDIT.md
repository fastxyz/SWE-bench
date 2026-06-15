# Public Compatibility Audit

Status: constructed, not machine-checked.

| Symbol / surface | Change | Public callers / overrides inspected | Result |
| --- | --- | --- | --- |
| `Collector.delete()` | Internal side effect added in one optimized branch; signature and return shape unchanged. | `Model.delete()`, `QuerySet.delete()`, Django admin/contenttypes callers through model/queryset delete. | Compatible. |
| `Model.delete()` | No source change. | Direct user-facing instance delete path. | Compatible; now receives corrected in-memory PK side effect from `Collector.delete()`. |
| `QuerySet.delete()` | No source change. | Queryset delete call path and result-cache clearing. | Compatible; no instance-specific PK cleanup obligation added. |
| `Collector.can_fast_delete()` | No source change. | Overrides in `contrib.admin.utils` and `contrib.contenttypes.management.commands.remove_stale_contenttypes`. | Compatible; V1 does not change the method signature or dispatch. |

No public API, virtual dispatch signature, return type, or storage format incompatibility was identified.

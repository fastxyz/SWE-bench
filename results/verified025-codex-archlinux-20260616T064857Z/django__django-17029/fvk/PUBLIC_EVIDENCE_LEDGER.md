# Public Evidence Ledger

| ID | Source | Evidence | Semantic obligation | Status |
| --- | --- | --- | --- | --- |
| E-001 | `benchmark/PROBLEM.md:3` | "`Apps.clear_cache()` does not clear `get_swappable_settings_name` cache." | Reported defect is stale swappable-settings cache after `clear_cache()`. | Encoded by PO-001 and PO-002. |
| E-002 | `benchmark/PROBLEM.md:8-11` | "`get_swappable_settings_name` ... is not cleared" and proposal to add `self.get_swappable_settings_name.cache_clear()` to `clear_cache`. | `clear_cache()` must call the swappable-settings cache clear operation. | Encoded by PO-001. |
| E-003 | `benchmark/PROBLEM.md:9` and `repo/django/apps/registry.py:370-374` | "`clear_cache` doc states: Clear all internal caches, for methods that alter the app registry." | Every internal app-registry cache affected by registry mutations must be invalidated. | Encoded by PO-001 through PO-004. |
| E-004 | `repo/django/apps/registry.py:168` and `repo/django/apps/registry.py:283-304` | `get_models()` and `get_swappable_settings_name()` are both decorated with `functools.cache`; `get_swappable_settings_name()` iterates over `get_models(include_swapped=True)`. | Both cached methods are app-registry caches; swappable lookup depends on current model state. | Encoded by PO-001 and PO-002. |
| E-005 | `repo/django/apps/registry.py:215-240`, `306-337`, `339-368` | Registry mutation methods call `self.clear_cache()`. | Fixing `clear_cache()` centralizes invalidation for all mutation paths already using it. | Encoded by PO-004. |
| E-006 | `repo/django/apps/registry.py:380-385` | `clear_cache()` expires per-model `_meta` caches only under `if self.ready`. | The cache fix must not remove or broaden the ready-gated model-meta expiry behavior. | Encoded by PO-003. |
| E-007 | `repo/django/db/models/fields/related.py:430-437` | `swappable_setting` calls `apps.get_swappable_settings_name(to_string)`. | Public callers must continue using the same zero-signature-change method. | Encoded by PO-005. |
| E-008 | `repo/django/db/migrations/state.py:136-140`, `640-649` | Migration state code calls `apps.clear_cache()` after unregister/bulk updates. | Existing consumers rely on central `clear_cache()` semantics. | Encoded by PO-004 and PO-005. |

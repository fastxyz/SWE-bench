# Public Compatibility Audit

Status: pass. V1 does not require source changes beyond the existing transaction wrapper.

| ID | Surface | Audit Result | Evidence |
| --- | --- | --- | --- |
| C-1 | Public API/signatures | No public method signature changed. `ModelAdmin.changelist_view()`, hooks, formset factories, and response methods keep the same parameters and return shapes. | Diff only adds a `with transaction.atomic(...)` block inside `options.py`. |
| C-2 | Branch selection | `_save` continues to route to list-editable processing; action "Go" handling remains outside that branch. | `options.py:2001-2002`; public tests at `tests.py:4280-4323`. |
| C-3 | Edited queryset narrowing | `_get_list_editable_queryset()` still runs before formset construction and before the transaction-wrapped save loop. | `options.py:2005-2011`; public test at `admin_changelist/tests.py:1148-1169`. |
| C-4 | Hook dispatch | Existing virtual hooks remain called in the same order: `save_form()`, `save_model()`, `save_related()`, `construct_change_message()`, `log_change()`. | `options.py:2015-2024`. |
| C-5 | Multidatabase convention | The new atomic block uses `router.db_for_write(self.model)`, matching add/change/delete admin transactions. | `options.py:1744-1746`, `:2014`, `:2103-2106`; `test_multidb.py:50-90`. |
| C-6 | Observable success response | `changecount`, success message, and redirect are preserved after the save loop. | `options.py:2026-2038`. |

Compatibility note: custom hook code now executes inside the model write transaction on the selected connection for list-editable saves. That is the requested behavior and matches the existing change-form transaction pattern. External side effects inside hooks remain an application-level concern because database rollback cannot undo them.

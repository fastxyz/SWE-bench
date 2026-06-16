# Public Evidence Ledger

| ID | Source | Quoted Evidence | Semantic Obligation | Status |
| --- | --- | --- | --- | --- |
| E1 | `benchmark/PROBLEM.md` | "Add transaction handling to Changelist list_editable processing." | The targeted behavior is the changelist `list_editable` save path, not unrelated admin views. | Encoded in `SPEC.md`, `changelist-list-editable-spec.k`, PO-1. |
| E2 | `benchmark/PROBLEM.md` | "changelist_view in Django admin is missing a transaction" | The candidate fix must add a transaction to the relevant `changelist_view()` database-changing path. | Encoded in PO-2 and PO-3. |
| E3 | `benchmark/PROBLEM.md` | "Since the view may change data in database, it should be wrapped in a transaction to prevent unexpected states in case of errors." | If an error occurs during the write sequence, earlier writes from the same list-editable processing must roll back. | Encoded in `LIST_EDITABLE_FAILURE_ROLLBACK`, PO-4. |
| E4 | `repo/django/contrib/admin/options.py:1744-1746` and `:2103-2106` | Existing admin `changeform_view()` and `delete_view()` use `transaction.atomic(using=router.db_for_write(self.model))`. | The changelist transaction should use the same router-selected write database convention. | Encoded in PO-6. |
| E5 | `repo/django/contrib/admin/options.py:2001-2024` | The list-editable branch checks POST/list_editable/_save, validates a formset, loops over changed forms, and calls save/log hooks. | The transaction must cover each changed form's write/log bundle while preserving branch selection and hook order. | Encoded in PO-1, PO-3, PO-5, PO-7. |
| E6 | `repo/tests/admin_views/tests.py:4280-4323` | Public tests distinguish action "Go" from list-editable "Save"; `_save` executes list-editable changes even with action choices present. | The fix must not change `_save` branch selection or action handling. | Compatibility audit pass C-2. |
| E7 | `repo/tests/admin_changelist/tests.py:1148-1169` | "list_editable edits use a filtered queryset to limit memory usage." | The fix must preserve edited-object queryset narrowing before formset processing. | Compatibility audit pass C-3. |
| E8 | `repo/tests/admin_views/test_multidb.py:50-90` | Existing add/change/delete multidatabase tests assert `mock.atomic.assert_called_with(using=db)`. | The router-selected DB alias is public behavior for admin transactional views. | Encoded in PO-6. |

No public evidence supports preserving the legacy absence of a transaction. Any test or observation requiring partial commits on list-editable errors would be SUSPECT because it would conflict with E1-E3.

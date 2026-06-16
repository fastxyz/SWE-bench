# Proof Obligations

Status key: `discharged` means discharged by source inspection and constructed proof; `residual` means documented but outside this fix's source-level control.

| ID | Obligation | Evidence | Status |
| --- | --- | --- | --- |
| PO-1 | The new transaction applies only to `changelist_view()` list-editable save processing: `POST`, `cl.list_editable`, and `"_save" in request.POST`, after change permission and successful formset validation. | `options.py:2001-2014`; ledger E1/E5/E6. | discharged |
| PO-2 | The list-editable write loop is enclosed in a transaction. | `options.py:2014`; ledger E2/E3. | discharged |
| PO-3 | The transaction covers the full per-form write/log bundle: `save_form()`, `save_model()`, `save_related()`, `construct_change_message()`, and `log_change()`. | `options.py:2015-2024`; ledger E5. | discharged |
| PO-4 | If any write bundle raises, earlier writes from the same submitted changed-form batch roll back rather than remaining committed. | K claim `LIST_EDITABLE_FAILURE_ROLLBACK`; ledger E3. | discharged, constructed not machine-checked |
| PO-5 | If no write bundle raises, exactly the changed forms are committed once and `changecount` still reflects changed forms. | K claim `LIST_EDITABLE_SUCCESS_COMMIT`; `options.py:2015-2024`; ledger E5. | discharged, constructed not machine-checked |
| PO-6 | The transaction uses Django admin's existing write-database convention, `router.db_for_write(self.model)`. | `options.py:1744-1746`, `:2014`, `:2103-2106`; `test_multidb.py:50-90`; ledger E4/E8. | discharged |
| PO-7 | The fix preserves non-target changelist behavior: action handling, invalid formset rendering, edited queryset filtering, hook order, message and redirect behavior. | `options.py:1914-2045`; public tests sampled in ledger E6/E7; compatibility audit C-1 through C-6. | discharged |
| PO-8 | The formal abstraction must distinguish the defect from the fix. | Counterfactual `processListEditableNoAtomic()` commits immediately; `processListEditable()` uses pending writes and rollback. | discharged |
| PO-9 | External side effects in custom hooks are not claimed to roll back. | Default-domain assumption in `INTENT_SPEC.md`; compatibility note C-6. | residual |

No proof obligation required a source change beyond V1.

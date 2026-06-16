# Baseline Notes

## Root cause

`ModelAdmin.changelist_view()` handled valid `list_editable` POST submissions by iterating over changed forms and calling `save_form()`, `save_model()`, `save_related()`, and `log_change()` without a surrounding transaction. If an exception occurred after one changed object had already been saved, earlier object changes and log entries could remain committed while later edits were not applied, leaving the changelist bulk edit in a partially updated state.

The admin change form and delete view already use `transaction.atomic(using=router.db_for_write(self.model))`, but the list-editable changelist save path did not.

## Files changed

`repo/django/contrib/admin/options.py`

Added `transaction.atomic(using=router.db_for_write(self.model))` around the per-form list-editable save loop in `ModelAdmin.changelist_view()`. The transaction covers the model save, related-object save hook, change-message construction, and admin log write for every changed form in the submitted formset.

## Assumptions and alternatives considered

I assumed the intended transaction boundary is the actual database-changing list-editable processing after `formset.is_valid()` succeeds. This keeps validation, permission checks, formset construction, success messages, and redirects outside the transaction while ensuring that all changed rows and their admin log entries commit or roll back together.

I considered wrapping the entire `changelist_view()` method, but rejected that as broader than necessary because GET rendering, action handling, invalid lookup redirects, and non-editing POST paths do not need to be held inside this transaction for the issue described.

I also considered wrapping each changed form independently, but rejected that because it would still allow partial success across a single submitted list-editable formset, which is the inconsistent state the issue reports.

No test files were modified, and no tests or project code were run per the task constraints.

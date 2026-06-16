# Findings

Status: V1 confirmed; no additional source change is justified by the FVK audit.

## F-1: Pre-fix partial commit bug

Classification: code bug in pre-fix behavior, resolved by V1.

Concrete input class: a valid list-editable POST with two changed forms where the second changed form raises during its save/log bundle.

Observed pre-fix behavior: without an enclosing transaction, the first form's database writes, and any writes in the failing second bundle before the exception, can remain committed.

Expected behavior from public intent: the submitted list-editable processing is all-or-nothing; an error during the batch must not leave earlier writes committed.

Formal witness: in the counterfactual no-atomic model, `processListEditableNoAtomic(2, 1)` increments committed state before failure. In V1's atomic model, `LIST_EDITABLE_FAILURE_ROLLBACK` leaves committed state unchanged for all `N >= 0` and `0 <= F < N`.

Related proof obligations: PO-2, PO-3, PO-4, PO-8.

## F-2: V1 transaction boundary is sufficient

Classification: confirmation.

The public issue targets database-changing `list_editable` processing. V1 places one `transaction.atomic(using=router.db_for_write(self.model))` around the complete changed-form write/log loop after formset validation succeeds.

This is sufficient because every source-level operation in the per-form database-changing bundle is inside the atomic block, and the K failure claim proves rollback for every failure position inside the modeled bundle sequence.

Related proof obligations: PO-1 through PO-6.

## F-3: No compatibility regression found

Classification: confirmation.

V1 does not alter public signatures, branch predicates, formset construction, edited queryset filtering, hook order, success-message construction, or redirect behavior. Public tests establish that `_save` selects list-editable processing and action "Go" does not; V1 preserves that split.

Related proof obligations: PO-7.

## F-4: External hook side effects remain outside database rollback

Classification: residual integration risk, not a V1 code bug.

Custom `save_model()`, `save_related()`, or `log_change()` overrides may perform external side effects such as email or writes to another database alias. `transaction.atomic()` cannot roll back those effects unless they participate in the same database transaction. This is also true of existing admin change-form transaction handling and is not uniquely introduced by V1.

Related proof obligations: PO-9.

## Proof-derived findings from `/verify`

The constructed proof did not force any new source precondition, ordering choice, or compatibility exception. The only residual item is PO-9, which is documented as a transaction semantics boundary rather than a reason to change Django admin source for this issue.

No tests were run and no test files were modified.

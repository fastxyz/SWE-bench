# FVK Spec: Django Admin `list_editable` Transaction Handling

Status: constructed, not machine-checked. No tests, Python, or K tooling were run.

## Target

Source under audit: `repo/django/contrib/admin/options.py`, specifically `ModelAdmin.changelist_view()` on the validated `list_editable` POST save path at `options.py:2001-2024`.

V1 candidate fix: `options.py:2014` adds:

```python
with transaction.atomic(using=router.db_for_write(self.model)):
```

around the changed-form save/log loop.

## Public Intent Ledger

The standalone ledger is in `PUBLIC_EVIDENCE_LEDGER.md`. Critical entries:

- E1-E3 from `benchmark/PROBLEM.md`: list-editable changelist processing must gain transaction handling to prevent unexpected database states on errors.
- E4/E8 from existing admin transaction patterns and multidatabase tests: use `router.db_for_write(self.model)` for the transaction alias.
- E5 from `options.py:2001-2024`: the write bundle for each changed form is `save_form()`, `save_model()`, `save_related()`, `construct_change_message()`, and `log_change()`.
- E6/E7 from public tests: preserve list-editable branch selection and edited-object queryset narrowing.

## Formal Contract

The K artifacts are:

- `mini-admin-transaction.k`: a small state-machine semantics for transaction processing.
- `changelist-list-editable-spec.k`: two reachability claims over that semantics.

### Claim 1: Failure Rollback

For any `N >= 0` changed-form write bundles and any failure index `F` where `0 <= F < N`, processing the list-editable save loop inside one atomic region leaves the committed database state unchanged, clears pending writes, exits the atomic region, and records failure.

This models the issue's required all-or-nothing behavior when an exception occurs after one or more changed forms have started writing.

### Claim 2: Success Commit

For any `N >= 0` changed-form write bundles and no failure index inside the loop, processing the list-editable save loop inside one atomic region commits exactly `N` write bundles, clears pending writes, exits the atomic region, and records success.

This preserves successful list-editable semantics while adding transaction handling.

## Source-Level Obligations

The proof obligations in `PROOF_OBLIGATIONS.md` bridge the K model back to Django source:

- Enter the transaction only on validated list-editable save processing.
- Cover the entire per-form database-changing sequence.
- Use one transaction for the whole submitted changed-form batch, not one transaction per form.
- Use `router.db_for_write(self.model)`.
- Preserve hook order, message behavior, redirect behavior, action handling, and queryset filtering.

## Scope and Boundaries

The formal model is not a full Python/Django semantics. It abstracts each changed form to one write bundle because the property under verification is committed state versus rollback state. This abstraction distinguishes the known failing class (partial commits without atomic) from the intended behavior (no partial commits with atomic).

External side effects in custom hooks and writes to other database aliases are outside the modeled transaction. This is a residual integration risk, not a defect in V1, because Django's existing admin change/delete transaction pattern has the same boundary.

# Formal Spec in English

The formal core is in `mini-admin-transaction.k` and `changelist-list-editable-spec.k`. It is constructed, not machine-checked.

## Claim: `LIST_EDITABLE_FAILURE_ROLLBACK`

For every `N >= 0` changed-form write bundles and every failure index `F` where `0 <= F < N`, executing `processListEditable(N, F)` starts an atomic region, processes write bundles in order, encounters a failure during bundle `F`, rolls back the atomic region, leaves the committed database write count unchanged, clears pending writes, exits the atomic region, and records failure.

Plain English: if any changed form fails during the transactional list-editable save loop, no write from that submitted list-editable batch remains committed.

## Claim: `LIST_EDITABLE_SUCCESS_COMMIT`

For every `N >= 0` changed-form write bundles and every failure index outside the processed range, executing `processListEditable(N, F)` starts an atomic region, processes all `N` write bundles, commits exactly `N` bundles, clears pending writes, exits the atomic region, and records success.

Plain English: if the validated list-editable save loop completes without error, every changed form's write bundle is committed once.

## Modeled frame conditions

The K model intentionally abstracts each changed form into one write bundle. This preserves the property axis under audit, committed writes versus rolled-back pending writes, while leaving detailed Django form validation, template rendering, and HTTP response construction outside the transaction proof.

The source-level frame condition is checked separately in `PUBLIC_COMPATIBILITY_AUDIT.md`: the patch does not change public method signatures, branch predicates, formset construction, hook order, success-message logic, or redirect logic.

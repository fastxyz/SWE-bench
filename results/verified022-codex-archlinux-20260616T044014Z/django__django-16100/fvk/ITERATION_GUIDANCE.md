# Iteration Guidance

## Decision

Keep V1 unchanged.

## Why

The FVK audit confirms that V1 satisfies the required transaction property:

- PO-2 and PO-3 show the entire changed-form save/log bundle is inside one `transaction.atomic()` block.
- PO-4 proves the rollback property in the formal transaction model.
- PO-5 proves successful processing still commits each changed form once.
- PO-6 confirms the transaction uses the existing admin write-database convention.
- PO-7 confirms no public compatibility regression was found.

## No Source Change Needed

No finding identified a defect requiring a V2 source edit. The only residual issue, F-4/PO-9, is an inherent transaction boundary for external side effects in custom hooks and is not specific to this changelist fix.

## Recommended Public Tests for a Future Test Pass

Do not modify tests in this benchmark task. For a normal Django patch, add tests that:

- use `list_editable` with at least two changed rows and force an exception during the second row's save/log processing, then assert the first row is rolled back;
- assert `transaction.atomic()` is called with `using=router.db_for_write(self.model)` for list-editable changelist POSTs;
- keep existing tests covering `_save` versus action submit behavior and edited queryset filtering.

## Machine Verification

The proof is constructed, not machine-checked. A future verification pass should run:

```sh
cd fvk
kompile mini-admin-transaction.k --backend haskell
kast --backend haskell changelist-list-editable-spec.k
kprove changelist-list-editable-spec.k
```

Until those commands return `#Top`, treat the proof as an audit artifact and do not delete any tests based on it.

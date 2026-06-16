# Formal Spec English

Status: paraphrase of `rename-model-spec.k`; constructed, not machine-checked.

## Claims

`RENAME-MODEL-NOOP-SAME-TABLE`

For any non-negative numbers of related-object edits and applicable M2M edits, if migration is allowed and the old and new model states identify the same database table, `RenameModel.database_forwards()` returns without changing the database-operation count.

`RENAME-MODEL-NOOP-DISALLOWED`

For any non-negative numbers of related-object edits and applicable M2M edits, if migration is not allowed for the model, `RenameModel.database_forwards()` returns without changing the database-operation count.

`RELATED-COUNT`

The abstract related-object loop emits exactly one database operation per related object in the non-no-op branch.

`M2M-COUNT`

The abstract local M2M loop emits exactly two database operations per applicable auto-created M2M relation in the non-no-op branch.

`RENAME-MODEL-DIFFERENT-TABLE-PRESERVES-WORK`

For any non-negative related-object and M2M counts, if migration is allowed and the old and new model states identify different database tables, `RenameModel.database_forwards()` emits one main table operation, one operation per related object, and two operations per applicable M2M relation.

## Frame Conditions

`state_forwards()` still calls `state.rename_model()`. The formal side-effect model does not rewrite or suppress migration state.

The public method signature of `RenameModel.database_forwards()` is unchanged.

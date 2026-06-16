# Baseline Notes

## Root cause

`CreateModel.reduce()` already knows how to absorb follow-up model operations that only refine the just-created model, including `AlterModelOptions`, `AlterTogetherOptionOperation`, `AlterOrderWithRespectTo`, and field operations. `AlterModelManagers` is also a state-only model operation, but it had no matching branch in `CreateModel.reduce()`, so the migration optimizer left `CreateModel` followed by `AlterModelManagers` as two operations instead of producing a single `CreateModel` with the final managers.

## Changed files

`repo/django/db/migrations/operations/models.py`

Added an `AlterModelManagers` branch to `CreateModel.reduce()`. When the operation targets the same model, the reducer now returns a replacement `CreateModel` with the same name, fields, options, and bases, but with `managers=operation.managers`. This mirrors `AlterModelManagers.state_forwards()`, which replaces the model state's manager list.

## Assumptions and alternatives

I assumed the optimizer should preserve the final state exactly as applying both operations in order would: the manager list from `AlterModelManagers` replaces the original managers on `CreateModel`.

I considered changing `ModelOptionOperation.reduce()` to make this more generic, but rejected it because `CreateModel` needs to construct a new operation with model-specific constructor arguments. A local `CreateModel.reduce()` branch matches the existing patterns for options and other model metadata.

I also considered merging manager lists, but rejected that because `ProjectState.alter_model_managers()` assigns `list(managers)` rather than appending or merging.

No tests or code were run, per the benchmark instructions.

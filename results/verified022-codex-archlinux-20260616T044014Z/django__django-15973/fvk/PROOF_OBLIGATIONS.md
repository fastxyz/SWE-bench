# FVK Proof Obligations

Status: constructed, not machine-checked.

## PO-1 - Preserve target dependency

Statement: for a non-swappable relation whose target resolves to `(A, M)`, `_get_dependencies_for_foreign_key()` returns `(A, M, None, True)`.

Evidence: existing branch at `repo/django/db/migrations/autodetector.py:1412-1422`.

V1 result: satisfied. The patch does not modify this branch.

## PO-2 - Resolve explicit through dependency from the through reference

Statement: if `field.remote_field.through` is truthy and resolves to `(TA, TM)`, `_get_dependencies_for_foreign_key()` returns `(TA, TM, None, True)`.

Evidence: issue example with `through="fonte_variavel.FonteVariavelModel"` and traceback from unresolved string through reference.

V1 result: satisfied by `resolve_relation(field.remote_field.through, app_label, model_name)` at `repo/django/db/migrations/autodetector.py:1424-1428`.

## PO-3 - Correct through dependency reaches migration ordering before optimization

Statement: the dependency from PO-2 must be attached to the related-field operation early enough for `_build_migration_list()` to split or order migrations before `_optimize_migrations()` can fold operations.

Evidence: related-field operation dependencies are attached at `repo/django/db/migrations/autodetector.py:687-703`; `_build_migration_list()` checks external dependencies at lines 300-341; `_optimize_migrations()` runs later at lines 403-419.

V1 result: satisfied. No additional production edit is required.

## PO-4 - Preserve no-through behavior

Statement: if a field has no explicit `through`, `_get_dependencies_for_foreign_key()` must not add a through-model dependency.

Evidence: `if getattr(field.remote_field, "through", None):` guards the added dependency.

V1 result: satisfied. The guard is unchanged.

## PO-5 - Preserve swappable-target behavior while fixing through

Statement: if `field.swappable_setting` is set, the first dependency remains `("__setting__", setting_name, None, True)`, and any explicit through dependency still resolves from `field.remote_field.through`.

Evidence: swappable branch at `repo/django/db/migrations/autodetector.py:1412-1416`; through branch at lines 1423-1429.

V1 result: satisfied. V1 does not alter the swappable target branch.

## PO-6 - Artifact honesty and reproducibility

Statement: because no execution environment is available and K tooling must not be run, proof artifacts must include commands but label the proof as constructed, not machine-checked.

Evidence: user no-exec instruction and FVK verify workflow.

V1/FVK result: satisfied in `fvk/PROOF.md`.

## Reduced K Claims

The reduced K formalization abstracts only the dependency helper's observable behavior. It is not a full Python or Django semantics.

Claims are written in `fvk/migration-autodetector-spec.k`:

- `EXPLICIT-THROUGH-CROSS-APP`: a non-swappable target plus cross-app explicit through produces both target and through dependencies.
- `NO-THROUGH`: a relation without explicit through produces only the target dependency.
- `SWAPPABLE-WITH-THROUGH`: a swappable target still produces the setting dependency and the explicit through dependency.

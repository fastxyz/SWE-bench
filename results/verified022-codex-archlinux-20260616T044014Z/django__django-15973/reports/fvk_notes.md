# FVK Notes

## Summary

The FVK audit confirmed the V1 production patch should stand unchanged. The public issue requires the migration autodetector to depend on an explicit many-to-many through model when that model is in another app. F1 identifies the V1 bug precisely, and PO-2 is discharged by resolving the extra dependency from `field.remote_field.through`.

## Decisions traced to findings and obligations

D1. Kept `repo/django/db/migrations/autodetector.py` unchanged after V1.

Trace: F1 is closed by PO-2. The current source uses `resolve_relation(field.remote_field.through, app_label, model_name)`, which produces the through app dependency required by the reported `fonte_variavel.FonteVariavelModel` case.

D2. Did not add schema-editor fallback logic for unresolved string through models.

Trace: F2 and PO-3 show the dependency is consumed by the migration graph before optimization. Fixing graph dependencies is the direct obligation; schema-editor fallback would mask an invalid historical state rather than generating a correct migration order.

D3. Did not change `ProjectState` model reloading.

Trace: F2 and PO-3 show the corrected external dependency reaches `_build_migration_list()` before `_optimize_migrations()`. The public failure is explained without a broader reload change.

D4. Preserved target, no-through, swappable, signature, and tuple-shape behavior.

Trace: F3 maps to PO-1, PO-4, and PO-5. V1 changes only the expression inside the existing explicit-through branch.

D5. Did not run or modify tests.

Trace: F4 and PO-6 record the no-execution constraint and the constructed-not-machine-checked status. Test guidance is included in `fvk/PROOF.md`, but no test files were edited.

## Net code changes in the FVK phase

No production source files were changed during the FVK phase. The only added files are FVK artifacts under `fvk/` and this report.

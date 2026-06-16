# FVK Notes

## Decision

V1 stands unchanged. The FVK audit found that the V1 source edits discharge the issue-derived obligations, and it did not surface an additional production-code change justified by the public evidence.

## Trace to Findings and Proof Obligations

`repo/django/db/models/fields/related.py` remains as V1 left it. This is justified by F1 and PO1: `ForeignKey.db_parameters()` now exposes the target field's `collation` while preserving the existing `type` and `check` behavior. PO2 then composes this with existing `column_sql()` and `_iter_column_sql()` behavior to cover create-model and add-field column SQL.

`repo/django/db/backends/base/schema.py` remains as V1 left it. This is justified by F2 and PO3: `drop_foreign_keys` now treats referenced primary key or unique collation changes as schema-significant. It is also justified by F3 and PO4: related FK column updates pass a collated type string through the existing backend type-alter hook, preserving MySQL nullability handling.

No additional propagation of target field metadata was added. F4 and PO5 confirm that copying only `collation` is the intended scope; target check constraints remain excluded from FK column parameters.

No compatibility code was added. F5 and PO5 found the `db_parameters()` shape change to be additive and consistent with existing `CharField`/`TextField` collation metadata, with no exact-dict public consumer found in the audited source.

No tests or verification tools were run. F6 and PO6 record the execution boundary required by the task. The FVK proof is constructed, not machine-checked, and the emitted K commands are documentation for a future environment.

## Artifacts Produced

The required artifacts are:

- `fvk/SPEC.md`
- `fvk/FINDINGS.md`
- `fvk/PROOF_OBLIGATIONS.md`
- `fvk/PROOF.md`
- `fvk/ITERATION_GUIDANCE.md`

The FVK formal core is also included:

- `fvk/mini-django-schema.k`
- `fvk/django-15629-spec.k`

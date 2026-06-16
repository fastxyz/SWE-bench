# FVK Findings

Status: constructed, not machine-checked. No tests or code were run.

## F1 - Pre-fix through dependency was resolved from the wrong reference

Classification: code bug, resolved by V1.

Input: a source app `fonte` with `ManyToManyField("variavel.VariavelModel", through="fonte_variavel.FonteVariavelModel")`.

Observed before V1: `_get_dependencies_for_foreign_key()` detected that `remote_field.through` existed, but resolved the extra dependency from `remote_field_model`. In the reported case, that produces another dependency on `variavel` instead of a dependency on `fonte_variavel`.

Expected: the through dependency must resolve from `field.remote_field.through`, producing a dependency on `fonte_variavel.FonteVariavelModel`.

Evidence: SPEC E1-E3; PROOF_OBLIGATIONS PO-2.

Decision: V1 changed `remote_field_model` to `field.remote_field.through` at `repo/django/db/migrations/autodetector.py:1425`. This finding is closed.

## F2 - Migration graph ordering uses the corrected helper output before optimization

Classification: confirmation of V1; no further code change.

Input: generated related-field operation for the reported many-to-many field.

Observed after static audit: related fields call `_get_dependencies_for_foreign_key()` and attach its dependency list to the operation at `repo/django/db/migrations/autodetector.py:687-703`. Migration file construction checks external dependencies at lines 300-341. Operation optimization runs later at lines 403-419.

Expected: a corrected cross-app through dependency must be visible to migration splitting before an `AddField` could be folded into `CreateModel`.

Evidence: SPEC E4-E5; PROOF_OBLIGATIONS PO-3.

Decision: V1 stands. No schema-editor tolerance hack or ProjectState reload change is needed for the public issue.

## F3 - No-through and swappable-target behavior must remain framed

Classification: compatibility obligation, satisfied by V1.

Input: a relation without explicit `through`, or a relation whose target is swappable and whose explicit through model is concrete.

Observed after static audit: V1 changes only the expression used inside the existing through branch. The target/swappable branch and no-through path are unchanged.

Expected: no explicit through means no extra through dependency; swappable target dependency remains a setting dependency while through dependency points to the explicit through model.

Evidence: SPEC I4; PROOF_OBLIGATIONS PO-1, PO-4, PO-5.

Decision: V1 stands.

## F4 - Residual verification caveat

Classification: proof process limitation, not a code bug.

Input: the FVK formal artifacts and proof commands.

Observed: K claims and proof are constructed but not machine-checked because the task forbids running K tooling.

Expected: artifacts must state the exact commands and keep all proof/test-removal conclusions conditioned on future machine checking.

Evidence: PROOF_OBLIGATIONS PO-6; PROOF "Machine-check commands".

Decision: no production-code change. Keep all verification language labeled constructed, not machine-checked.

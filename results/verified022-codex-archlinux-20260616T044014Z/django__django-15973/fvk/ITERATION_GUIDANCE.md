# FVK Iteration Guidance

Status: V1 stands unchanged after FVK audit.

## Decisions

D1. Keep the V1 production code change.

Reason: F1 identifies the exact pre-fix bug, and PO-2 is discharged by the current line `resolve_relation(field.remote_field.through, app_label, model_name)`.

D2. Do not add schema-editor handling for unresolved string `through` references.

Reason: F2 and PO-3 show the intended correction is in migration dependency generation. Schema editing should receive a historical app registry whose related models are already ordered and rendered.

D3. Do not change `ProjectState` reload behavior.

Reason: F2 and PO-3 show the missing cross-app dependency is enough to reach migration ordering before optimization. Broad cache/reload behavior is outside the public issue and not needed to discharge the proof obligations.

D4. Do not modify tests.

Reason: the task forbids editing tests. FVK proof is constructed, not machine-checked, and cannot justify removing tests.

## Recommended Future Work

When execution is available, run the normal Django migration autodetector tests plus a targeted regression test for a cross-app explicit through model. The expected result is that the generated migration set includes a dependency path through the intermediary model's app and no longer leaves `field.remote_field.through` unresolved at schema creation.

Potential regression test shape:

```text
from_state: empty project
to_state:
  fonte.FonteModel with M2M to variavel.VariavelModel through fonte_variavel.FonteVariavelModel
  variavel.VariavelModel
  fonte_variavel.FonteVariavelModel with FKs to fonte and variavel
expected:
  FonteModel's M2M AddField or optimized CreateModel is ordered after the through model migration dependency.
```

## Stop Condition

No further source edits are recommended unless a future executable test or machine-checked proof exposes an obligation not covered by PO-1 through PO-6.

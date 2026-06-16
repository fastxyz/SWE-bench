# FVK Iteration Guidance

Status: constructed, not machine-checked. No tests, Python, or K tooling were run.

## Decision

V1 stands unchanged.

The FVK audit confirmed that the issue is the target-state lookup key inside
`generate_renamed_fields()`. The proof obligations show that, after a model
rename, `old_model_name` is the correct key for `from_state` and `model_name`
is the correct key for `to_state`. V1 implements that split exactly.

## Guidance for This Patch

Do not add a fallback around `to_state.models[...]`. The proof localizes the
bug to the key choice, not to missing error handling. A fallback would obscure
the invariant and could hide malformed autodetector state.

Do not change `_prepare_field_lists()`. Its use of the new kept model key for
field tuples is required so later field operations refer to the renamed model.

Do not change tests in this benchmark pass. The task forbids test edits, and
the proof is constructed rather than machine-checked.

## Suggested Public Regression Test Shape

For a future normal Django development environment, add a test that builds a
from-state with model `MyModel` and field `old_field`, a to-state with model
`MyModel2` and field `new_field`, accepts the model rename and field rename,
and asserts that autodetection produces `RenameModel` and `RenameField` without
raising `KeyError`.

## Open Items

The full Django migration autodetector remains outside this focused proof. If
a later FVK pass needs to verify more than the reported state-key crash, extend
the model to cover relation deconstruction, questioner policy, migration
operation dependencies, and graph arrangement.

# Baseline Notes

## Root cause

`MigrationAutodetector.generate_renamed_models()` records model renames by
mapping the new model key to the old model name, and updates
`self.old_model_keys` so later model/field comparison uses the new model key.
`generate_renamed_fields()` correctly used that mapping to read the old model
from `from_state`, but then reused the old model name when reading the model
from `to_state`.

When a model and one of its fields were renamed in the same autodetection pass,
the new project state only contained the new model name. Looking up
`self.to_state.models[app_label, old_model_name]` therefore raised `KeyError`
before field rename detection could compare the fields.

## Changed files

`repo/django/db/migrations/autodetector.py`

Changed `generate_renamed_fields()` so the old model state is still read from
`from_state` with the old model name, while the new model state is read from
`to_state` with the current model name. This matches the surrounding
autodetector methods and the way `self.renamed_models` is populated.

## Assumptions

The reported crash is caused by the target-state lookup during field rename
detection, not by the earlier model rename detection. After a rename,
`model_name` in `self.new_field_keys` and `self.old_field_keys` is the new model
key, while `old_model_name` is only needed to address `from_state`.

## Alternatives considered

One alternative was to change `_prepare_field_lists()` to keep old field keys
under the old model name. I rejected that because later autodetector logic
expects renamed models to be treated as kept models under the new key, and other
methods already use `old_model_name` only for `from_state` lookups.

Another alternative was to special-case missing `to_state` models in
`generate_renamed_fields()`. I rejected that because the correct target model is
already known as `model_name`; falling back around the lookup would hide the
state mismatch instead of fixing it.

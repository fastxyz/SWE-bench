# Baseline Notes

## Root cause

`Field.__hash__()` included model metadata from `self.model._meta` when a field had been attached to a model. A field instance starts without `self.model`, then `contribute_to_class()` assigns it during model class construction. This made the hash value change after insertion into a dictionary or set, so lookups using the same field instance could fail once the model was created.

`Field.__eq__()` still compares both `creation_counter` and model identity. Using only `creation_counter` for the hash keeps the hash stable while preserving the hash contract: fields that compare equal have the same `creation_counter`, and fields that compare unequal may share a hash collision safely.

## Changed files

`repo/django/db/models/fields/__init__.py`

Changed `Field.__hash__()` to return `hash(self.creation_counter)` instead of hashing a tuple containing mutable attachment state from `self.model`. This directly addresses the reported failure for fields used as dictionary keys before assignment to a model class.

`reports/baseline_notes.md`

Added this required report documenting the root cause, source change, assumptions, and alternatives considered.

## Assumptions and alternatives considered

Assumed `creation_counter` is the intended stable identity component for field hashing because it is assigned during `Field.__init__()` and is already the primary ordering key for fields.

Considered removing `Field.__hash__()` entirely, but that would make fields unhashable because `Field` defines `__eq__()`, which would break existing use cases that store fields in dictionaries or sets.

Considered storing a separate immutable model label at construction time, but model attachment does not exist at construction time and adding new state would be unnecessary for the reported issue.

Considered changing `Field.__eq__()` to ignore model identity as well, but the issue only requires hash stability. Keeping equality unchanged preserves the behavior introduced to distinguish fields from different models that share a creation counter.

No tests or project code were run, per the task constraints.

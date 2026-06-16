# Baseline Notes

## Root cause

`ModelChoiceIteratorValue` wraps the prepared model choice value and model instance for `ModelChoiceField` options. It defines `__eq__()` so that wrappers compare equal to either another wrapper with the same `.value` or directly to the underlying primitive value.

In Python, defining `__eq__()` without defining `__hash__()` makes instances unhashable. As a result, code that used a select option value in a hash-based lookup, such as `value in {1: [...]}`, raised `TypeError: unhashable type: 'ModelChoiceIteratorValue'`. Sequence membership such as `value in [1, 2]` still worked because it only needed equality comparisons.

## Changed files

`repo/django/forms/models.py`

Added `ModelChoiceIteratorValue.__hash__()` returning `hash(self.value)`. This keeps hash behavior consistent with the existing value-based equality behavior and allows instances to participate in dictionary and set membership checks when the wrapped value itself is hashable.

## Assumptions and rejected alternatives

I assumed `ModelChoiceIteratorValue` should behave as much like its wrapped prepared value as possible, because the existing `__str__()` and `__eq__()` implementations already expose that behavior.

I considered changing widget option creation to pass the primitive `.value` instead of the wrapper, but rejected that because the wrapper also carries `.instance` for documented customization use cases.

I considered hashing by object identity or by the model instance, but rejected those because they would be inconsistent with `__eq__()`, where equality is based on `self.value`.

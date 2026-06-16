# Public Compatibility Audit

Status: constructed, not machine-checked.

Changed public symbol: `django.forms.models.ModelChoiceIteratorValue`.

Change: add `__hash__(self)`.

Compatibility result: pass.

Reasoning:

- No constructor signature changes.
- No changes to `__str__()` or `__eq__()`.
- No changes to `ModelChoiceIterator.choice()`; it still returns `(ModelChoiceIteratorValue(prepared_value, obj), label)`.
- No changes to `ChoiceWidget.create_option()` or the option context shape; user overrides still receive the wrapper as `value`.
- Existing code that treated the wrapper as unhashable should only observe a new successful hash operation when `.value` is hashable.
- Existing code with an unhashable wrapped `.value` still receives `TypeError` from `hash(self.value)`, matching the hash-table domain boundary.

Rejected compatibility-changing alternatives:

- Replacing the wrapper with the primitive prepared value would change the producer/consumer shape and remove `.instance`.
- Adding `__bool__()` would change truthiness for falsey but valid prepared values such as `0`; the public issue does not require that behavior.

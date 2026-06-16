# Intent Spec

Status: intent-only, derived from the public issue text, public hint text, and the audited source code shape. Current implementation behavior is recorded only as behavior to check.

## Intent obligations

I1. `ModelChoiceIteratorValue` instances used as select option values must be hashable whenever their wrapped `.value` is hashable. The issue reports `TypeError: unhashable type: 'ModelChoiceIteratorValue'` as the bug, and the public hint proposes `__hash__()` returning `hash(self.value)`.

I2. A wrapper must compare by the wrapped prepared value. The issue says list membership such as `value in [1, 2]` works, and the source already implements `__eq__()` by comparing `self.value` to either another wrapper's `.value` or to the other object.

I3. Dictionary membership and indexing with a wrapper must behave like membership and indexing with the wrapped value when the wrapped value is hash-equal and equality-equal to a dictionary key. The issue's concrete example uses `{1: ['first_name', 'last_name']}` and then performs `value in self.show_fields` and `self.show_fields[value]`.

I4. The wrapper must keep carrying the model instance. `ModelChoiceIterator.choice()` constructs `ModelChoiceIteratorValue(self.field.prepare_value(obj), obj)`, so replacing the wrapper with the primitive value would remove the `.instance` channel available to option customization.

I5. No new public API signature or return-shape change is required. The public request is about hashability of the existing wrapper object, not about changing `create_option()`, `ModelChoiceIterator.choice()`, or `ModelChoiceField.prepare_value()`.

## Domain assumptions

D1. Hash-table behavior is specified for wrapped values whose `hash(value)` is defined. If the wrapped value is unhashable, `ModelChoiceIteratorValue.__hash__()` may raise `TypeError`, matching Python's normal requirement that dictionary and set keys be hashable.

D2. The proof is partial with respect to user-defined `value.__eq__()`, `value.__hash__()`, and `value.__str__()` methods: it assumes those methods terminate and obey Python's own hash/equality contract for the wrapped value.

D3. Dictionary lookup is proved for the issue's ordinary key case, such as integer key `1`, and for keys whose equality comparison with the wrapper delegates to or agrees with wrapped-value equality. Exotic custom keys whose `__eq__()` deliberately returns `False` for wrappers even when they compare equal to the wrapped primitive are outside the public evidence.

## Out-of-scope alternatives checked

A1. Adding `__bool__()` was considered because the issue's snippet contains `if not value`, but the reported failure and public hint are specifically about hashability. Empty choices are represented by the empty string path in `ModelChoiceIterator.__iter__()`, while valid model choices may have falsey prepared values such as `0`; changing truthiness would introduce extra public behavior without intent evidence.

A2. Replacing the wrapper with `value.value` was rejected because it would satisfy dictionary lookup but would lose `.instance`, contrary to the wrapper's producer shape in `ModelChoiceIterator.choice()`.

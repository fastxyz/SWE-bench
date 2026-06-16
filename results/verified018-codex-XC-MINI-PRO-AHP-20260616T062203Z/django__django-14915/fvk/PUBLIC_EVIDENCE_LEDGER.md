# Public Evidence Ledger

E1. Source: prompt issue description.
Quote: `Error is {TypeError}unhashable type: 'ModelChoiceIteratorValue'.`
Obligation: `ModelChoiceIteratorValue` must not be unhashable when used in hash-based lookup with a hashable wrapped value.
Status: encoded in `SPEC.md`, `model-choice-iterator-value-spec.k`, PO2, PO4, and PO5.

E2. Source: prompt issue example.
Quote: `if value in self.show_fields: # This is a dict {1: ['first_name', 'last_name']}`
Obligation: dictionary membership with a wrapper around `1` must succeed instead of raising, and lookup by that wrapper must retrieve the same entry as lookup by `1`.
Status: encoded in PO4 and PO5.

E3. Source: prompt contrast case.
Quote: `However, working with arrays is not an issue` and `if value in allowed_values: # This is an array [1, 2]`.
Obligation: value-based equality already works and must be preserved.
Status: encoded in PO1 and PO3.

E4. Source: public hint in problem statement.
Quote: `we could make ModelChoiceIteratorValue hashable by adding: def __hash__(self): return hash(self.value)`.
Obligation: hash code must be derived from the wrapped prepared value, not object identity or model instance identity.
Status: encoded in PO2 and PO3.

E5. Source: source code, `repo/django/forms/models.py`.
Quote: `ModelChoiceIteratorValue(self.field.prepare_value(obj), obj)`.
Obligation: the option value wrapper carries both prepared value and model instance; the fix must not remove the wrapper.
Status: encoded in PO6 and FINDINGS F3.

E6. Source: source code, `repo/django/forms/widgets.py`.
Quote: `subgroup.append(self.create_option(name, subvalue, sublabel, ...))` and `return {'value': value, ...}`.
Obligation: user overrides of `create_option()` receive the same option value object that came from choices.
Status: encoded in PO5 and PO6.

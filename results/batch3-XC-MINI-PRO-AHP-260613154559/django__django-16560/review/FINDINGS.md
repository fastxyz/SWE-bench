# Code review — django__django-16560 (V1 fix audit)

Feature under review: add a `violation_error_code` parameter to `BaseConstraint`
(and `CheckConstraint`, `UniqueConstraint`, `ExclusionConstraint`) so the `code`
of the `ValidationError` raised during model validation can be customized,
mirroring the existing `violation_error_message`.

Scope of V1: `django/db/models/constraints.py`,
`django/contrib/postgres/constraints.py`, plus docs and the 5.0 release note.

Legend: ✅ confirmed correct · ⚠️ issue requiring a change · 🛈 considered / no
change.

---

## Correctness against the issue

### Finding 1 — Core feature is wired correctly ✅
`CheckConstraint.validate`, both customizable branches of
`UniqueConstraint.validate` (the `expressions` branch and the `condition`
branch), and both branches of `ExclusionConstraint.validate` now raise
`ValidationError(self.get_violation_error_message(), code=self.violation_error_code)`.
`ValidationError.__init__(message, code=None, ...)` assigns `self.code = code`
for scalar messages (`core/exceptions.py:173-176`), so the raised exception's
`.code` equals the configured value. With the default `violation_error_code =
None`, the call is equivalent to the previous `ValidationError(message)`, so
behavior is unchanged unless a code is explicitly provided. End-to-end:
`cm.exception.code` after `constraint.validate(...)` returns the custom code.

### Finding 2 — `__init__` stores the attribute correctly ✅
`BaseConstraint.__init__` only overwrites the class-level
`violation_error_code = None` when a non-`None` value is passed
(`if violation_error_code is not None: self.violation_error_code = ...`). This
matches the established pattern and avoids shadowing the class attribute with an
instance `None`. The three subclasses thread the argument through to
`super().__init__(...)`.

---

## Edge cases & boundary conditions

### Finding 3 — `validate_constraints` crashes when a non-unique constraint carries `code="unique"` ⚠️ (fixed)
`django/db/models/base.py:1447-1451`:

```python
if (
    getattr(e, "code", None) == "unique"
    and len(constraint.fields) == 1
):
    errors.setdefault(constraint.fields[0], []).append(e)
```

This branch unconditionally reads `constraint.fields`. Only `UniqueConstraint`
has a `fields` attribute; `CheckConstraint` and `ExclusionConstraint` do not.

*Before V1* this was safe: the only way an error reached here with
`code == "unique"` was via `instance.unique_error_message()`, which is only
raised by a fields-based `UniqueConstraint`, so `constraint.fields` always
existed.

*After V1* a user can write
`CheckConstraint(check=..., name=..., violation_error_code="unique")` (or the
same on `ExclusionConstraint`). On violation, `validate()` raises a
`ValidationError` whose `code` is `"unique"`, the first `and` operand becomes
`True`, and `len(constraint.fields)` raises
`AttributeError: 'CheckConstraint' object has no attribute 'fields'` — turning a
clean validation failure inside `full_clean()` into an unhandled crash.

This is a regression directly enabled by making `code` user-controllable, so it
must be hardened. Fix: guard the attribute access with
`len(getattr(constraint, "fields", [])) == 1`. The semantics become: a
non-unique constraint that happens to carry `code="unique"` is treated as a
non-field error (the `else` branch), which is the correct outcome. Behavior for
real `UniqueConstraint`s is byte-for-byte identical because they always have
`.fields`. (The sibling access `constraint.fields[0]` is reached only when the
guard already proved `len(...) == 1`, so it stays safe and needs no change.)

### Finding 4 — Default-`None` code is preserved through model validation ✅
For a custom non-`"unique"` code, `validate_constraints` falls to the `else`
branch and calls `e.update_error_dict(errors)`, which appends the
`ValidationError` instance (with its `.code` intact) to the `NON_FIELD_ERRORS`
bucket (`core/exceptions.py:197-199`). The custom code therefore survives to the
final aggregated `ValidationError`.

### Finding 5 — Backward-compat unique path intentionally ignores the code ✅
The single-field, no-`condition` branch of `UniqueConstraint.validate` keeps
raising `instance.unique_error_message(...)` (code `"unique"` /
`"unique_together"`) and does **not** apply `violation_error_code`. This is
deliberate and consistent: `violation_error_message` is already documented as
*not used* for these constraints, so `violation_error_code` follows the same
rule. The new docs for `UniqueConstraint.violation_error_code` state this
exclusion explicitly. Leaving this branch untouched is correct.

---

## Interactions / possible regressions in surrounding code

### Finding 6 — No regression in `repr` / `__eq__` / `deconstruct` for existing constraints ✅
With `violation_error_code = None` (the default and every existing test):
- `__repr__`: the new conditional slot renders `""`, so outputs are unchanged.
  Verified against `tests/constraints/tests.py::test_repr_with_violation_error_message`
  and `tests/postgres_tests/test_constraints.py::test_repr`.
- `__eq__`: adds `None == None`, which never flips an existing comparison.
- `deconstruct`: the key is emitted only `if self.violation_error_code is not
  None`, so existing deconstruction output (e.g.
  `BaseConstraintTests::test_deconstruction`) is unchanged.

### Finding 7 — All `BaseConstraint` subclasses covered; `deconstruct` inheritance intact ✅
A repository search confirms exactly three subclasses: `CheckConstraint`,
`UniqueConstraint`, `ExclusionConstraint` — all updated for
`__init__`/`__eq__`/`__repr__`/`validate`. None override `deconstruct` in a way
that drops base kwargs; each calls `super().deconstruct()` and only adds keys, so
`violation_error_code` propagates through `clone()` and migration serialization
for every subclass.

### Finding 8 — Deprecated positional-args path is correct ✅
The deprecation map stays `["name", "violation_error_message"]`.
`violation_error_code` is new and was never positional, so it is correctly
keyword-only. The `__init__` ordering (set `violation_error_code` before the
positional `args` loop) means a mix such as
`BaseConstraint("name", violation_error_code="x")` still assigns both correctly.

---

## Consistency with codebase conventions

### Finding 9 — `%r` formatting and attribute defaults match conventions ✅
`__repr__` uses `%r` for the code, matching the message slot. The class-level
default `violation_error_code = None` mirrors `violation_error_message = None`.
The docs and 5.0 release note were updated in parallel with the existing
`violation_error_message` entries.

### Finding 10 — No `get_violation_error_code()` getter 🛈 (no change)
Considered adding a getter symmetric with `get_violation_error_message()`.
Rejected: the message getter exists solely to perform `%(name)s` interpolation
(`violation_error_message % {"name": self.name}`); a code needs no formatting, so
a getter would be a trivial passthrough. A test verifying the code naturally
inspects the `.violation_error_code` attribute or `cm.exception.code` after
`validate()`, neither of which needs a getter. Keeping the surface minimal.

### Finding 11 — Cosmetic ordering of the new key in `deconstruct` 🛈 (no change)
`deconstruct` appends `violation_error_code` after `violation_error_message`,
whereas `__init__`/`__repr__` list code before message. This affects only the
left-to-right order of kwargs in generated migration source; dict equality
(used by `test_deconstruction`) is order-independent and runtime behavior is
unaffected. Not worth the churn; left as-is.

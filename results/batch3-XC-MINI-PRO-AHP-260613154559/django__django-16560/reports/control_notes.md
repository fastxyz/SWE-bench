# Control notes — django__django-16560 (V2)

This document explains every V2 decision and ties it to the numbered entries in
`review/FINDINGS.md`. V1 (described in `reports/baseline_notes.md`) added a
`violation_error_code` parameter to `BaseConstraint`, `CheckConstraint`,
`UniqueConstraint`, and the PostgreSQL `ExclusionConstraint`, threading it through
`__init__`, `deconstruct`, `__eq__`, `__repr__`, and the `ValidationError` raises
in each `validate()`, plus docs and a 5.0 release note.

## Change made in V2

### 1. Hardened `Model.validate_constraints` against a non-unique constraint carrying `code="unique"`
**File:** `django/db/models/base.py`
**Traces to:** Finding 3 (with Finding 4 confirming the resulting behavior).

V1 made the `ValidationError.code` user-controllable for `CheckConstraint` and
`ExclusionConstraint`, neither of which has a `fields` attribute. The error
collector in `validate_constraints` did:

```python
if getattr(e, "code", None) == "unique" and len(constraint.fields) == 1:
    errors.setdefault(constraint.fields[0], []).append(e)
```

Before V1 this was safe because only a fields-based `UniqueConstraint` could
produce `code == "unique"` (via `unique_error_message()`). After V1, a user
writing `CheckConstraint(..., violation_error_code="unique")` would make the
first operand `True` and then trip `len(constraint.fields)` →
`AttributeError`, crashing `full_clean()` instead of reporting the validation
error. I changed the guard to:

```python
if getattr(e, "code", None) == "unique" and len(getattr(constraint, "fields", [])) == 1:
```

- For every `UniqueConstraint` the result is identical (it always has `.fields`),
  so no existing behavior — and no existing test — changes (Finding 6).
- For a `CheckConstraint`/`ExclusionConstraint` that happens to carry
  `code="unique"`, the guard is now `False` and the error flows to the `else`
  branch (`update_error_dict`), surfacing as a `NON_FIELD_ERRORS` entry with the
  custom code preserved (Finding 4). That is the correct outcome: a non-unique
  constraint has no single field to attach the error to.
- The sibling access `constraint.fields[0]` is only reached after the guard has
  proven `len(...) == 1`, so it remains safe and is left unchanged.

This is the minimal hardening that removes the crash while preserving all
established behavior; it is in-scope because the crash is a direct interaction
of the new feature with surrounding code.

## Parts of V1 deliberately kept unchanged

### 2. Core wiring of `violation_error_code` stands
**Traces to:** Findings 1, 2, 7, 9.
The attribute, constructor threading, and the `code=self.violation_error_code`
arguments on every customizable `ValidationError` raise are correct and
end-to-end functional (`ValidationError.__init__` assigns `.code`). All three
subclasses are covered, `deconstruct` propagation via `super().deconstruct()` is
intact, and conventions (`%r`, `None` defaults, parallel docs) are respected. No
change needed.

### 3. The fields-based, no-`condition` `UniqueConstraint` branch keeps using `unique_error_message()`
**Traces to:** Finding 5.
This branch intentionally ignores both `violation_error_message` and
`violation_error_code` for backward compatibility, matching the documented
contract. Applying the custom code here would change long-standing behavior of
field-based unique validation and contradict the docs. Left unchanged.

### 4. No `get_violation_error_code()` getter added
**Traces to:** Finding 10.
`get_violation_error_message()` exists only because the message requires
`%(name)s` interpolation; a code has nothing to format, so a getter would be a
pure passthrough. Verification of the code is done through the
`.violation_error_code` attribute or `cm.exception.code`. Keeping the API
surface minimal.

### 5. `repr` / `eq` / `deconstruct` shape and the deprecated positional path
**Traces to:** Findings 6, 8, 11.
The new repr slot renders empty when the code is `None`, so existing repr/eq/
deconstruct expectations are preserved; the deprecated positional map correctly
excludes the new keyword-only argument. The only nit — that `deconstruct` lists
the new key after `violation_error_message` while `__init__`/`__repr__` list it
before — is purely cosmetic (dict equality is order-independent) and was left
as-is to avoid needless churn.

## Net result
V1's feature implementation was correct and is retained in full. The single V2
code change is a one-line defensive guard in `validate_constraints` that closes
an `AttributeError` crash path newly reachable because the feature lets users set
an arbitrary `code` (including `"unique"`) on constraints that lack a `fields`
attribute. Documentation and the release note from V1 remain accurate and
unchanged.

# FVK Findings

Status: constructed from source review; not machine-checked.

## Summary

No V2 production-code change is required. The V1 patch satisfies the
intent-derived obligations in `fvk/SPEC.md` for the audited methods.

## Findings

F1. Disabled callable initial mismatch is addressed.

- Evidence: `SPEC.md` I1 and I3.
- Pre-V1 observed behavior: `_clean_fields()` used
  `get_initial_for_field(field, name)` directly for disabled fields, while
  `form[name].initial` used the cached `BoundField.initial` path.
- Expected behavior: disabled field cleaning must use the same bound-field
  initial value exposed by `form[name].initial`.
- V1 status: satisfied. `BaseForm._clean_fields()` now iterates
  `_bound_items()` and sets `value = bf.initial if field.disabled else bf.data`.
- Classification: fixed code bug.

F2. `FileField` initial consistency is addressed.

- Evidence: `SPEC.md` I1 and I2.
- Pre-V1 observed behavior: `FileField` cleaning obtained its `initial`
  argument by calling `get_initial_for_field(field, name)` directly.
- Expected behavior: the initial argument supplied to `FileField.clean()` should
  come from the same `BoundField` object used for the field.
- V1 status: satisfied. `_clean_fields()` calls `field.clean(value, bf.initial)`
  for `FileField`.
- Classification: fixed duplicated-path risk.

F3. `changed_data` per-field logic is moved to `BoundField`.

- Evidence: `SPEC.md` I2 and I4.
- Pre-V1 observed behavior: `BaseForm.changed_data` duplicated per-field data,
  initial, hidden-initial, and `ValidationError` handling.
- Expected behavior: `BaseForm.changed_data` should aggregate per-field
  decisions from bound fields.
- V1 status: satisfied. `changed_data` is now a list comprehension over
  `_bound_items()` and calls `bf._has_changed()`.
- Classification: fixed duplicated-path risk.

F4. Hidden-initial change behavior is preserved.

- Evidence: `SPEC.md` S4 and S5.
- Observed V1 behavior: `BoundField._has_changed()` retains the old
  `show_hidden_initial` path: read hidden widget data, convert it with
  `field.to_python()`, return changed on `ValidationError`, otherwise call
  `field.has_changed(initial, self.data)`.
- Expected behavior: the refactor should not change hidden-initial semantics.
- V1 status: satisfied by structural equivalence to the old
  `BaseForm.changed_data` branch.
- Classification: no code bug found.

F5. Public compatibility risk is acceptable for this patch.

- Evidence: `SPEC.md` S5; source search found no in-repo custom
  `get_bound_field()` implementation returning a non-`BoundField` object.
- Observed V1 behavior: `changed_data` now expects each bound field returned by
  `field.get_bound_field()` to provide private method `_has_changed()`.
- Expected behavior: Django's own fields return `django.forms.boundfield.BoundField`;
  subclasses that return a compatible bound field are expected to behave as
  bound fields.
- V1 status: acceptable. No public method signature changed. The new method is
  private and lives on Django's `BoundField`. Adding a fallback in
  `BaseForm.changed_data` would reintroduce the duplicate form-level path that
  the public issue asks to remove.
- Classification: residual compatibility note, not a code bug.

F6. Proof artifacts are constructed, not executed.

- Evidence: `SPEC.md` I5.
- Observed audit condition: the benchmark forbids running tests, Python, or K
  tooling.
- Expected behavior: record proof obligations and commands without executing
  them.
- V1 status: satisfied. No tests or verification tooling were run in this FVK
  pass.
- Classification: verification limitation, not a code bug.

# FVK Spec

Status: constructed, not machine-checked. No tests, Python, or K tooling were
run.

## Scope

The audited behavior is the password field used by Django auth change forms:
`ReadOnlyPasswordHashField.__init__()` and Django's generic field-cleaning rule
in `BaseForm._clean_fields()`. The observable under verification is the
password value placed in `cleaned_data` for a bound form.

The model deliberately excludes password hashing, rendering summaries, model
validation, database writes, and admin routing because none of those change the
field disabled flag or the cleaned password value.

## Intent Spec

I1. Source: `benchmark/PROBLEM.md`

Quote: "Set disabled prop on ReadOnlyPasswordHashField"

Obligation: a default `ReadOnlyPasswordHashField()` must be disabled.

Status: encoded by claim `C1`.

I2. Source: `benchmark/PROBLEM.md`

Quote: "this property could be set to True be default"

Obligation: the field's default is disabled, but explicit caller configuration
is not described as forbidden.

Status: encoded by claims `C1`, `C3`, and `C4`.

I3. Source: `benchmark/PROBLEM.md`

Quote: "Even if a user tampers with the field's value submitted to the server,
it will be ignored in favor of the value from the form's initial data."

Obligation: for a disabled password field, every submitted password value is
ignored and the initial password value is cleaned.

Status: encoded by claim `C2`.

I4. Source: `benchmark/PROBLEM.md`

Quote: "the potential pitfall when using the ReadOnlyPasswordHashField without
implementing clean_password is removed."

Obligation: custom forms using `ReadOnlyPasswordHashField()` without a
`clean_password()` override must still ignore tampered submitted password data.

Status: encoded by the composition of `C1` and `C2`.

I5. Source: `repo/docs/topics/auth/customizing.txt`

Quote: the custom `UserChangeForm` example used to define `clean_password()` to
return `self.initial["password"]`.

Obligation: this was legacy guidance for the pre-fix behavior. After I1-I4, the
docs example must not continue to present `clean_password()` as required for the
custom form pattern described in the issue.

Status: resolved by removing that method from the docs example.

I6. Source: `repo/django/forms/forms.py`

Quote: `if field.disabled: value = self.get_initial_for_field(field, name)`

Obligation: the implementation mechanism that discharges I3 is Django's generic
disabled-field cleaning path.

Status: used as implementation evidence in `C2`.

## Formal Spec English

C1. `disabledOf(defaultRPHF(none)) => true`

Constructing `ReadOnlyPasswordHashField` without an explicit disabled argument
produces a field whose disabled flag is true.

C2. `cleanPassword(defaultRPHF(none), SUB, INIT) => INIT`

For every submitted value `SUB` and initial value `INIT`, cleaning the default
read-only password hash field returns `INIT`.

C3. `disabledOf(defaultRPHF(some(false))) => false`

If a caller explicitly passes `disabled=False`, the constructor preserves that
explicit opt-out.

C4. `cleanPassword(defaultRPHF(some(false)), SUB, INIT) => SUB`

The explicit opt-out keeps normal submitted-data cleaning behavior.

There are no loops or recursive functions in the audited slice, so there are no
loop circularity obligations.

## Spec Audit

`C1`: pass. It directly states I1 and the default part of I2.

`C2`: pass. It states I3 for all submitted and initial password values and
discharges the custom-form part of I4 when composed with C1.

`C3`: pass. I2 says "by default", and Django field constructors commonly allow
explicit keyword overrides. The code uses `setdefault()`, so preserving an
explicit override is a compatibility frame rather than a new behavior.

`C4`: pass. This is the corresponding frame condition for C3 and follows from
the existing generic form-cleaning branch when a field is not disabled.

Docs obligation I5: pass after the V2 docs edit. The custom-user docs example no
longer instructs users to add `clean_password()` with `ReadOnlyPasswordHashField`.

## Public Compatibility Audit

Changed public symbol: `django.contrib.auth.forms.ReadOnlyPasswordHashField`.

Signature compatibility: pass. The constructor signature remains `*args,
**kwargs`.

Default behavior compatibility: intentionally changed. A default field is now
disabled, matching the issue.

Explicit override compatibility: pass. `kwargs.setdefault("disabled", True)`
preserves `ReadOnlyPasswordHashField(disabled=False)`.

Subclass/callsite compatibility: pass. Existing built-in `UserChangeForm` keeps
its `clean_password()` method. It is redundant after C1/C2 but still returns the
same initial password value and avoids removing a method that subclasses may
call or override.

Documentation compatibility: pass after V2. The custom-user docs example no
longer teaches the obsolete compensating hook.

## Formal Core

K files:

- `fvk/mini-django-forms.k`
- `fvk/readonly-password-hash-field-spec.k`

The exact commands to machine-check later, not executed here:

```sh
cd fvk
kompile mini-django-forms.k --backend haskell
kast --backend haskell readonly-password-hash-field-spec.k
kprove readonly-password-hash-field-spec.k
```

# Proof Obligations

Status: constructed, not machine-checked. No tests, Python, or K tooling were
run.

## PO1 - Default Disabled Flag

Claim: constructing `ReadOnlyPasswordHashField()` without an explicit disabled
kwarg yields a field with `disabled == True`.

Evidence: intent I1 and I2; source edit in
`repo/django/contrib/auth/forms.py`.

K claim: `disabledOf(defaultRPHF(none)) => true`.

Finding link: F1, F2.

## PO2 - Disabled Cleaning Uses Initial Value

Claim: for all password values `SUB` and `INIT`, cleaning a disabled password
field returns `INIT`, not `SUB`.

Evidence: intent I3; implementation branch in `BaseForm._clean_fields()`.

K claim: `cleanPassword(field(true), SUB, INIT) => INIT`, composed in the spec
as `cleanPassword(defaultRPHF(none), SUB, INIT) => INIT`.

Finding link: F1, F2.

## PO3 - Custom Forms Need No clean_password Hook

Claim: a custom form using default `ReadOnlyPasswordHashField()` and no
`clean_password()` override still ignores tampered submitted password data.

Evidence: intent I4.

Derivation: PO1 constructs a disabled field; PO2 then forces cleaning to return
the initial value.

Finding link: F1, F2.

## PO4 - Explicit disabled=False Is Preserved

Claim: `ReadOnlyPasswordHashField(disabled=False)` remains possible and keeps
normal submitted-data cleaning behavior.

Evidence: intent I2 says "by default"; compatibility audit for public field
constructor kwargs; source uses `setdefault()`.

K claims:

- `disabledOf(defaultRPHF(some(false))) => false`
- `cleanPassword(defaultRPHF(some(false)), SUB, INIT) => SUB`

Finding link: F4.

## PO5 - Built-In UserChangeForm Compatibility

Claim: leaving `UserChangeForm.clean_password()` in place is behaviorally
compatible with PO1-PO3.

Evidence: the method returns `self.initial.get("password")`, the same value the
disabled-field cleaning path selects for the built-in form. Public intent says
the method is unnecessary, not that it must be removed.

Finding link: F4.

## PO6 - Documentation Must Stop Requiring clean_password

Claim: the custom-user admin docs example must not continue to require
`clean_password()` for `ReadOnlyPasswordHashField`.

Evidence: intent I4 and docs evidence I5.

Resolution: V2 removes the obsolete method from
`repo/docs/topics/auth/customizing.txt`.

Finding link: F3.

## K Claims

The formal claims are in `fvk/readonly-password-hash-field-spec.k`, backed by
the mini semantics in `fvk/mini-django-forms.k`.

Exact commands to machine-check later, not executed here:

```sh
cd fvk
kompile mini-django-forms.k --backend haskell
kast --backend haskell readonly-password-hash-field-spec.k
kprove readonly-password-hash-field-spec.k
```

Expected result if the mini semantics and claims parse and discharge:
`kprove` returns `#Top`.

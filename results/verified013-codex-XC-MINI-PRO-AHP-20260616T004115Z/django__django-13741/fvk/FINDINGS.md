# FVK Findings

Status: constructed, not machine-checked. No tests, Python, or K tooling were
run.

## F1 - Pre-V1 Custom Form Tampering Bug

Classification: code bug, resolved by V1.

Input: a custom `ModelForm` declares `password = ReadOnlyPasswordHashField()`,
does not define `clean_password()`, has initial password value `INIT`, and
receives submitted password value `SUB`.

Observed before V1: because `ReadOnlyPasswordHashField.disabled` defaulted to
false, `BaseForm._clean_fields()` read the submitted value from the widget data
path. Without a custom `clean_password()`, `cleaned_data["password"]` could be
`SUB`.

Expected: per intent entries I3 and I4, the submitted value must be ignored and
`cleaned_data["password"]` must be `INIT`.

Resolution: `repo/django/contrib/auth/forms.py` now sets
`kwargs.setdefault("disabled", True)` in `ReadOnlyPasswordHashField.__init__()`.
This discharges proof obligations PO1 and PO2.

## F2 - V1 Runtime Fix Satisfies the Field-Level Contract

Classification: confirmed behavior, constructed proof obligation.

Input: `ReadOnlyPasswordHashField()` with no explicit disabled kwarg, any
submitted password `SUB`, and any initial password `INIT`.

Observed after V1 by source inspection: the field default is disabled, and
`BaseForm._clean_fields()` uses `get_initial_for_field()` for disabled fields.

Expected: `cleaned_data["password"] == INIT`.

Resolution: no additional source-code edit is needed. This is covered by PO1,
PO2, and PO3.

## F3 - V1 Left Stale Custom-User Documentation

Classification: documentation bug, resolved by V2.

Input: a developer follows the custom user admin example in
`repo/docs/topics/auth/customizing.txt`.

Observed in V1: the example still defined `clean_password()` and its comment
said the field did not have access to the initial value.

Expected: the issue says that with `ReadOnlyPasswordHashField` disabled by
default, `clean_password()` is no longer necessary and the custom-form pitfall is
removed.

Resolution: the V2 audit removed the obsolete `clean_password()` method from the
custom-user docs example. This discharges PO6.

## F4 - Removing UserChangeForm.clean_password Is Not Required

Classification: rejected alternative, compatibility frame.

Input: code or subclasses that call or override `UserChangeForm.clean_password`.

Observed in V1 and V2: the method remains present and returns the initial
password value.

Expected: the field-level default must make the method unnecessary for
correctness, but public intent does not require removing the method. Keeping it
does not reintroduce the tampering bug because it returns the same initial value
as the disabled-field path.

Resolution: keep the method. This decision is covered by PO5.

## F5 - Proof Honesty Boundary

Classification: proof capability / execution boundary.

Input: all proof obligations in `fvk/readonly-password-hash-field-spec.k`.

Observed: the proof was constructed by source inspection and symbolic reasoning
only. The K commands were written down but not executed, as required by the task.

Expected: artifacts must be labeled "constructed, not machine-checked"; tests
must not be removed based on this proof.

Resolution: proof and iteration guidance keep that caveat explicit.

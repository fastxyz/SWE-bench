# FVK Spec

Status: constructed, not machine-checked. No tests, Python code, `kompile`, or
`kprove` were run.

## Scope

Target unit: the relevant straight-line part of
`repo/django/contrib/auth/forms.py::AuthenticationForm.__init__()` after
`super().__init__()` has populated `self.fields`.

There are no loops or recursive calls in the audited code slice. The observable
under verification is the initialized `username` form field: its `max_length`,
its widget attributes used for rendering, and its label behavior.

## Intent Spec

I1. `AuthenticationForm` must render the username field with a `maxlength` HTML
attribute.

I2. The username length used by `AuthenticationForm` must come from the active
user model's `USERNAME_FIELD.max_length`, with a fallback of `254` when that
model field has no `max_length`.

I3. Django's `CharField` widget-attribute contract must hold: if a non-hidden
character field has `max_length = L`, its widget attrs contain
`maxlength = str(L)`.

I4. Existing label behavior must be preserved: an unset username label is
derived from the user model field verbose name, while an explicit label,
including an empty string, is not overwritten.

I5. Compatibility with subclasses that replace `username` with another field
type must be preserved. In particular, a non-character field should not receive
a manually forced `maxlength`; the field's own `widget_attrs()` method decides
which widget attrs apply.

## Public Evidence Ledger

| ID | Source | Evidence | Obligation | Status |
| --- | --- | --- | --- | --- |
| E1 | prompt | "AuthenticationForm's username field doesn't set maxlength HTML attribute." | Rendered username widget must include `maxlength`. | Encoded by claims C1 and C2. |
| E2 | prompt | "doesn't render with maxlength HTML attribute anymore" | The defect is in rendered HTML/widget attrs, not merely the Python field attribute. | Encoded; V1 changes widget attrs after dynamic length selection. |
| E3 | source comment | `# Set the max length and label for the "username" field.` | `AuthenticationForm.__init__()` is the intended place to set username max length and label. | Encoded as straight-line postconditions. |
| E4 | public tests | `test_username_field_max_length_matches_user_model` expects `255`. | Positive user-model max length is used as the field max length. | Encoded. |
| E5 | public tests | `test_username_field_max_length_defaults_to_254` expects `254` when model field max length is `None`. | Fallback length is `254`. | Encoded. |
| E6 | source and public tests | `CharField.widget_attrs()` adds `maxlength` when `max_length` is set and widget is not hidden. | Updating field `max_length` after `Field.__init__()` must also refresh widget attrs. | Encoded. |
| E7 | public tests | AuthenticationForm subclasses preserve custom labels and allow an `IntegerField` username. | The fix must not alter labels or force character-only attrs onto custom non-character fields. | Encoded and checked in compatibility audit. |
| E8 | implementation | `Field.__init__()` calls `self.widget_attrs(widget)` before `AuthenticationForm.__init__()` later assigns `username.max_length`. | Pre-V1 root cause: field state and widget attrs diverged. | Finding F-001 resolved by V1. |

## Formal Model

The K-style artifacts are:

- `fvk/mini-django-form.k`: a minimal, property-complete semantics for the
  audited form-initialization slice.
- `fvk/authentication-form-spec.k`: reachability claims for the username
  field's dynamic max-length and widget-attribute behavior.

The model abstracts away database access, authentication, request storage, and
template rendering internals because they do not affect the verified observable.
It retains the discriminating axis of the bug: whether the widget attrs contain
the effective `maxlength`.

The model uses:

- `LengthOpt`: `someLength(ML)` for a positive model-field length or
  `noLength()` for the fallback case.
- `FieldKind`: `usernameField()`, `charField()`, or `otherField()`.
- `widgetAttrs(kind, hidden, L)`: the field-specific widget attrs after the
  field's effective `max_length` is known.
- `mergeAttrs(A, extra)`: Django-style `widget.attrs.update(extra)`.

## Formal Spec English

Claim C1: For any positive model username length `ML`, initializing
`AuthenticationForm` with a non-hidden `UsernameField` sets the form field's
max length to `ML`, updates the widget attrs with `UsernameField.widget_attrs()`,
and therefore includes `maxlength = str(ML)` along with the username-specific
attrs.

Claim C2: If the active user model username field has no `max_length`,
initializing `AuthenticationForm` with a non-hidden `UsernameField` sets the form
field's max length to `254` and updates the widget attrs so `maxlength = "254"`.

Claim C3: If a subclass replaces `username` with a non-character field, the
form still records the effective max length as before, but the fix does not
manually inject a `maxlength`; the field's own `widget_attrs()` result controls
the widget attrs.

Frame condition FC1: Request storage, `user_cache`, password field behavior,
authentication, and error messages are unchanged by the V1 patch.

Frame condition FC2: Label behavior is unchanged except for the pre-existing
rule that an unset label is filled from the user model field verbose name.

## Spec Audit

| Claim | Adequacy result | Reason |
| --- | --- | --- |
| C1 | Pass | Directly matches E1, E2, E4, and E6. |
| C2 | Pass | Directly matches E1, E2, E5, and E6. |
| C3 | Pass | Directly matches E7 and avoids over-preserving candidate behavior by delegating to the field contract. |
| FC1 | Pass | V1 only changes local handling of the username field after `super().__init__()`; no other code paths are edited. |
| FC2 | Pass | V1 preserves the existing label branch while replacing repeated dictionary lookups with a local variable. |

No formal-English claim is candidate-derived without public evidence. The proof
does not rely on hidden tests, upstream patches, benchmark result files, or
internet evidence.

## Public Compatibility Audit

Changed public symbol: `AuthenticationForm.__init__()` implementation only. Its
signature, return value, attributes, and superclass call are unchanged.

Public callers:

- `django.contrib.auth.views.LoginView` uses `AuthenticationForm` as its
  `form_class`; no call signature changed.
- `django.contrib.admin.forms.AdminAuthenticationForm` subclasses
  `AuthenticationForm`; no override signature or dispatch call changed.

Subclass and custom-field compatibility:

- Public tests define subclasses with custom labels. V1 keeps the existing
  label branch unchanged.
- Public tests define a subclass with `username = IntegerField()`. V1 calls the
  field's own `widget_attrs()` and therefore does not manually force a
  `maxlength` onto non-character fields.
- `UsernameField.widget_attrs()` still contributes `autocapitalize` and
  `autocomplete`; V1 reuses that same method after assigning the dynamic
  `max_length`.

Compatibility verdict: no public API or subclass contract break was found.

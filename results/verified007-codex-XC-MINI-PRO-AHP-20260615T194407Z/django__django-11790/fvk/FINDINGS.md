# FVK Findings

Status: constructed, not machine-checked. Findings are derived from public
intent, source inspection, and the constructed proof obligations only.

## F-001: Resolved - V1 fixes the reported missing `maxlength`

Input: default `AuthenticationForm` using the built-in `User.username` character
field with model max length `150`.

Observed before V1: `AuthenticationForm.__init__()` assigned
`self.fields['username'].max_length = 150`, but the widget attrs had already
been populated earlier by `Field.__init__()` when `max_length` was still `None`.
The rendered username widget therefore omitted `maxlength`.

Expected: the rendered username widget includes `maxlength = "150"`.

V1 result: after assigning `username.max_length`, V1 calls
`username.widget.attrs.update(username.widget_attrs(username.widget))`. For a
non-hidden `UsernameField`, `CharField.widget_attrs()` contributes
`{'maxlength': '150'}`, and `UsernameField.widget_attrs()` preserves the
username autocomplete/autocapitalize attrs.

Classification: code bug resolved. Related proof obligations: PO-001, PO-002.

## F-002: Resolved - custom user-model lengths and fallback lengths are covered

Input A: active user model username field has `max_length = 255`.

Expected A: `AuthenticationForm.fields['username'].max_length == 255`, and the
non-hidden username widget attrs include `maxlength = "255"`.

Input B: active user model username field has no `max_length`.

Expected B: `AuthenticationForm.fields['username'].max_length == 254`, and the
non-hidden username widget attrs include `maxlength = "254"`.

V1 result: both cases use the same effective length expression,
`self.username_field.max_length or 254`, before refreshing widget attrs.

Classification: reported behavior family resolved. Related proof obligations:
PO-001, PO-002.

## F-003: Confirmed - V1 avoids forcing `maxlength` onto non-character fields

Input: a subclass of `AuthenticationForm` replaces `username` with
`IntegerField()`.

Expected: authentication behavior remains compatible with that subclass; the
fix should not manually add character-field HTML attrs to a non-character field.

V1 result: V1 does not directly assign `widget.attrs['maxlength']`. It delegates
to `username.widget_attrs(username.widget)`, so field-specific behavior remains
under the concrete field class.

Classification: compatibility preserved. Related proof obligation: PO-004.

## F-004: Open but out of scope - runtime validator parity is not established by the issue

Input: a username string longer than the active user model username length.

Observed after V1 by source reasoning: V1 refreshes widget attrs but does not
rebuild `CharField` validators. If a field was constructed without
`max_length`, its validator list was populated before the dynamic
`max_length` assignment.

Possible expectation: a field whose `max_length` is dynamically set might also
run a matching `MaxLengthValidator`, mirroring a `CharField(max_length=L)`
constructed with that length.

Reason not changed in this pass: the public issue specifically reports the
missing rendered `maxlength` HTML attribute, and public auth tests in scope
assert the field's `max_length` value rather than overlong-input validation
errors. Adding or replacing validators would alter runtime validation and error
surface beyond the HTML regression. That broader behavior should be handled by a
separate intent statement or public test.

Classification: underspecified intent / possible future enhancement, not a
blocker for V1. Related proof obligation: PO-005.

## F-005: Tooling not executed

The FVK proof is constructed but not machine-checked. The emitted commands in
`fvk/PROOF.md` are the commands to run later in an environment with K installed.

Classification: proof process limitation required by the task. Related proof
obligation: PO-006.

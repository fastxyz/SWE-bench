# FVK Proof Obligations

Status: constructed, not machine-checked.

## PO-001: Effective Username Length

For every `AuthenticationForm` instance after `super().__init__()`:

- If `UserModel._meta.get_field(UserModel.USERNAME_FIELD).max_length` is a
  positive integer `L`, then `self.fields['username'].max_length == L`.
- If that model field max length is absent or falsey, then
  `self.fields['username'].max_length == 254`.

Evidence: E3, E4, E5. Discharged by V1's assignment:
`username.max_length = self.username_field.max_length or 254`.

## PO-002: Rendered `maxlength` for Non-Hidden Username Character Fields

For a non-hidden `UsernameField` or compatible `CharField` username field, after
PO-001 selects effective length `L`, the widget attrs must include
`maxlength = str(L)`.

Evidence: E1, E2, E6. Discharged by V1's call:
`username.widget.attrs.update(username.widget_attrs(username.widget))`.

Reasoning: `CharField.widget_attrs()` returns `{'maxlength': str(L)}` when
`max_length` is not `None` and the widget is not hidden. `UsernameField` extends
that dictionary with username-specific attrs, so updating the widget with the
post-assignment result makes the rendered widget carry `maxlength`.

## PO-003: Label Preservation

If `username.label is None`, the label becomes `capfirst(verbose_name)` from the
user model username field. If `username.label` is any explicit value, including
the empty string, it is preserved.

Evidence: E3, E7. Discharged because V1 leaves the pre-existing label branch
semantically unchanged.

## PO-004: Custom Field Compatibility

The fix must not require the username field to be a `UsernameField`, must not
change `AuthenticationForm.__init__()`'s public signature, and must not manually
force a `maxlength` attr onto non-character username fields.

Evidence: E7 and public subclass/callsite search. Discharged because V1 uses
the existing field object, calls its polymorphic `widget_attrs()` method, and
does not alter method signatures or external call shapes.

## PO-005: Scope Boundary for Runtime Validators

The FVK proof for this issue is obligated to prove rendered HTML/widget attrs,
not a new overlong-input validation policy.

Evidence: E1 and E2 name the missing rendered `maxlength` HTML attribute as the
regression. Public evidence in this task does not require changing
`AuthenticationForm` validation errors for overlong usernames.

Discharged by keeping V1 focused on widget attrs and recording Finding F-004 as
an out-of-scope ambiguity rather than a source change.

## PO-006: Adequacy and Honesty Gate

Every formal claim must trace to public intent, and the proof must be labeled
constructed, not machine-checked.

Evidence: FVK docs and the task's no-execution constraint. Discharged by
including provenance in `fvk/SPEC.md`, embedding K-style artifacts under `fvk/`,
and recording commands in `fvk/PROOF.md` without running them.

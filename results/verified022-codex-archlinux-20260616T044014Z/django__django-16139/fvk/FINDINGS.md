# FVK Findings

Status: constructed, not machine-checked.

## F-001 - Pre-fix to_field link resolves to the wrong object id

Classification: code bug, repaired by V1.

Input: a saved user has primary key `PK = "1"` and a referenced `to_field` value
`TOFIELD = "22222222-3333-4444-5555-666677778888"`. The admin change URL is
`.../user/22222222-3333-4444-5555-666677778888/change/?_to_field=uuid`.

Observed pre-fix: `UserChangeForm` emits `../password/`, which resolves to
`.../user/22222222-3333-4444-5555-666677778888/password/`. `UserAdmin` then
looks up a primary key equal to the UUID segment and can return 404.

Expected: the help link resolves to `.../user/1/password/`, or more generally
`.../user/<admin-quoted primary key>/password/`.

Evidence: E-1, E-2, E-3. Proof obligation: PO-2.

Recommended code/spec change: keep V1's pk-based relative link.

## F-002 - Raw primary-key interpolation would under-specify admin path quoting

Classification: corner case avoided by V1.

Input: a saved user has a string primary key containing admin path-special
characters, for example `PK = "a/b"`.

Observed with the raw-pk alternative from the issue text: a relative link shaped
like `../../a/b/password/` puts a slash inside the object path segment and does
not match admin's object-id quoting discipline.

Expected: admin object path segments use `django.contrib.admin.utils.quote()`,
for example the segment is derived from `quote(PK)`, so `unquote(segment) = PK`
inside the password view.

Evidence: E-5. Proof obligations: PO-1 and PO-5.

Recommended code/spec change: keep V1's `quote(self.instance.pk)` use rather
than downgrading to raw `self.instance.pk`.

## F-003 - A form-local relative URL is the narrowest adequate repair

Classification: design decision confirmed.

Input: `UserChangeForm.__init__()` formats a field help string while it has an
instance but no request object and no active admin site name.

Observed alternative: using `reverse()` inside the form would require admin-site
context that the form API does not carry. Changing
`UserAdmin.user_change_password()` to honor `_to_field` would broaden the lookup
semantics of the password view rather than fixing the link that points to it.

Expected: the form emits a relative URL that is correct from both pk and
`to_field` change URLs.

Evidence: E-3, E-4. Proof obligations: PO-2 and PO-3.

Recommended code/spec change: keep the relative-link approach and do not change
`UserAdmin.user_change_password()`.

## F-004 - Unsaved and password-field-removed form cases remain framed

Classification: compatibility frame condition, confirmed.

Input: `UserChangeForm()` without a saved instance, or a subclass with
`password = None`.

Observed V1: when `self.instance.pk is None`, V1 keeps `../password/`; when the
password field is absent, the existing `if password:` guard keeps the branch a
no-op.

Expected: no new `None` primary-key URL is introduced, and password-field
removal remains supported.

Evidence: E-6, E-7. Proof obligations: PO-4 and PO-6.

Recommended code/spec change: keep V1's fallback and field-existence guard.

## F-005 - Proof boundary: constructed URL model, not machine-checked

Classification: proof capability and execution boundary.

Input: all claims in `fvk/user-change-form-spec.k`.

Observed: the proof is constructed from a small URL/path model and was not run
through `kompile` or `kprove` because the task forbids K tooling and code
execution.

Expected before test removal or machine-verification claims: run the emitted
commands and obtain `#Top`.

Evidence: FVK instructions and task no-exec constraint. Proof obligations:
PO-7.

Recommended code/spec change: no production-code change; keep integration tests
until machine checking is available.

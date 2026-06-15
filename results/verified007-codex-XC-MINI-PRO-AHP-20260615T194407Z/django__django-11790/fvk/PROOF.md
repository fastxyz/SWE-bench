# FVK Proof

Status: constructed, not machine-checked. No tests, Python, `kompile`, `kast`,
or `kprove` were run.

## Claims Proved in the Constructed Model

C1. For any positive user-model username length `ML`, initializing
`AuthenticationForm` with a non-hidden `UsernameField` sets the field max length
to `ML` and updates widget attrs with `maxlength = str(ML)`.

C2. If the user-model username field has no max length, initializing
`AuthenticationForm` with a non-hidden `UsernameField` uses fallback `254` and
updates widget attrs with `maxlength = "254"`.

C3. If a subclass supplies a non-character username field, the fix delegates to
that field's own `widget_attrs()` result instead of manually adding
`maxlength`.

## Constructed Symbolic Execution

The audited code path is straight-line after `super().__init__()`:

```python
self.username_field = UserModel._meta.get_field(UserModel.USERNAME_FIELD)
username = self.fields['username']
username.max_length = self.username_field.max_length or 254
username.widget.attrs.update(username.widget_attrs(username.widget))
if username.label is None:
    username.label = capfirst(self.username_field.verbose_name)
```

For C1, start from a state whose user-model length is `ML > 0`, whose username
field kind is `UsernameField`, and whose widget is not hidden.

1. The effective-length expression rewrites to `ML`.
2. The `username.max_length` store cell rewrites from its prior value to `ML`.
3. `username.widget_attrs(username.widget)` is evaluated after step 2. For a
   non-hidden `UsernameField`, it expands to the `CharField` attrs plus
   username attrs; the `CharField` portion includes `maxlength = str(ML)`.
4. `widget.attrs.update(...)` rewrites the attrs map by overriding/inserting the
   returned keys, so the final attrs map contains `maxlength = str(ML)`.
5. The label branch either preserves an explicit label or fills an unset label,
   matching PO-003.

For C2, the proof is identical except the effective-length expression rewrites
`None`/absent length to `254`, so the final attrs map contains
`maxlength = "254"`.

For C3, the field kind is `otherField()`. The constructed semantics of
`widgetAttrs(otherField(), hidden, L)` is `.Map`, representing the public
compatibility decision that the concrete non-character field controls its own
attrs. Updating with `.Map` leaves the attrs unchanged, so no manually forced
`maxlength` appears.

There are no loop circularities or termination measures because the audited code
slice has no loops.

## Verification Conditions

VC1. `ML > 0` implies `effectiveLength(someLength(ML)) == ML`.

VC2. `effectiveLength(noLength()) == 254`.

VC3. For non-hidden `UsernameField`, `widgetAttrs(usernameField(), false, L)`
contains `maxlength = str(L)`.

VC4. `mergeAttrs(A, extra)` preserves all unrelated attrs and overwrites only
keys present in `extra`, matching Django's `dict.update()` behavior.

VC5. The label branch preserves explicit labels and fills only `None` labels.

All VCs are first-order rewrites over the mini model; no arithmetic beyond the
positive-length side condition is required.

## Reproduce the Machine Check Later

These commands are intentionally recorded, not executed:

```sh
kompile fvk/mini-django-form.k --backend haskell
kast --backend haskell fvk/authentication-form-spec.k
kprove fvk/authentication-form-spec.k
```

Expected result: `kprove` discharges the claims to `#Top`.

## Test Guidance

No test files were modified. Because the proof is not machine-checked, no test
removal is recommended.

Recommended tests to keep or add in the fixed project:

- Keep existing public auth tests that cover dynamic username `max_length`,
  custom labels, and integer username subclasses; they cover integration and
  compatibility outside this mini proof.
- Add or keep a regression test asserting that `AuthenticationForm()` renders
  the username widget with the effective `maxlength` attribute.
- Add or keep custom-user regression points for `max_length = 255` and fallback
  `254` if the project wants explicit rendered-HTML coverage for those cases.

## Residual Risk

The proof is partial and constructed only. It depends on the adequacy of the
mini model, especially the abstraction of `widget_attrs()` and `dict.update()`.
Runtime validator parity for dynamically assigned `max_length` is recorded as
Finding F-004 and was not changed because it is outside the public HTML
regression.

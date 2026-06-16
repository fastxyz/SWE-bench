# FVK Proof Obligations

Status: constructed, not machine-checked.

## PO1: Blank radio fields preserve explicit empty_label

For all label values `L`, if:

- `db_field.name in self.radio_fields`;
- `"widget" not in kwargs`;
- `db_field.blank is True`;
- `"empty_label" in kwargs` and `kwargs["empty_label"] == L`;

then after the admin radio branch, `kwargs["empty_label"] == L`.

Evidence: E1, E2, E3, E5. Related findings: F1, F2.

## PO2: Blank radio fields without empty_label keep the admin default

If:

- `db_field.name in self.radio_fields`;
- `"widget" not in kwargs`;
- `db_field.blank is True`;
- `"empty_label" not in kwargs`;

then after the admin radio branch, `kwargs["empty_label"] == _("None")`.

Evidence: E1 describes the old default as wrong only when it overrides a custom
value. Related findings: F1.

## PO3: Nonblank radio fields keep empty-choice suppression

If:

- `db_field.name in self.radio_fields`;
- `"widget" not in kwargs`;
- `db_field.blank is False`;

then after the admin radio branch, `kwargs["empty_label"] is None`.

Evidence: `ModelChoiceField` suppresses the empty label for nonblank
`RadioSelect` widgets. Related findings: F3.

## PO4: Later queryset handling does not mutate empty_label

After the radio branch, the only later mutation before `db_field.formfield()` is
optional assignment of `kwargs["queryset"]`. Therefore the `empty_label` value
established by PO1, PO2, or PO3 is framed through to `db_field.formfield()`.

Evidence: source control flow in `formfield_for_foreignkey()`. Related findings:
F1, F4.

## PO5: Public override compatibility is preserved

The fix must not alter the `formfield_for_foreignkey(db_field, request,
**kwargs)` signature or require callers/overrides to pass a new argument.

Evidence: Django admin docs for overriding `formfield_for_foreignkey()`. Related
findings: F4.

## PO6: Truthiness fallback is rejected

The expression `kwargs.get("empty_label") or _("None")` must not be used as the
specification because it fails PO1 for explicit falsy values that
`ModelChoiceField` accepts.

Evidence: forms docs for `empty_label=None`. Related findings: F2.

## PO7: Verification honesty

The proof is partial-correctness reasoning over an abstract branch model. The
exact K commands are recorded but not executed; test removal or claims of
machine verification are out of scope.

Evidence: task no-execution rule and FVK honesty gate. Related findings: F5.

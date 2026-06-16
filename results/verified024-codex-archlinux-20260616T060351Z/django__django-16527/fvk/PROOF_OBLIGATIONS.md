# Proof Obligations

Status: constructed, not machine-checked.

## PO-1: Add permission necessity

For every in-domain submit-row context, if `has_add_permission` is false then
`show_save_as_new` is false.

Evidence: I1 and I2. Finding: F1. Formal claim: `NO_ADD`.

Status: discharged by V1 because the expression contains
`and has_add_permission`.

## PO-2: Current-object change necessity

For every in-domain submit-row context, if `has_change_permission` is false or
`change` is false then `show_save_as_new` is false.

Evidence: I3. Finding: F2. Formal claim: `NO_CHANGE`.

Status: discharged because V1 preserves `and has_change_permission` and
`and change`.

## PO-3: Popup and feature-flag exclusions

For every in-domain submit-row context, if `is_popup` is true or `save_as` is
false then `show_save_as_new` is false.

Evidence: existing source behavior plus no public issue evidence requesting a
change to popup or `save_as` handling.

Status: discharged because V1 preserves `not is_popup` and `and save_as`.

## PO-4: Positive visibility case

For every in-domain submit-row context, if all of these hold:

```text
is_popup = false
has_add_permission = true
has_change_permission = true
change = true
save_as = true
```

then `show_save_as_new` is true.

Evidence: I2 and I3.

Status: discharged by the full conjunction.

## PO-5: Template rendering link

The `submit_line.html` template renders the `_saveasnew` input if and only if
`show_save_as_new` is true.

Evidence: I4.

Status: discharged by source inspection; no template edit is needed.

## PO-6: Compatibility and frame condition

The fix must not change `submit_row(context)`'s signature, required context keys,
or unrelated submit-row flags.

Evidence: I5 and public compatibility audit.

Status: discharged. V1 changes only the boolean expression for
`show_save_as_new`.

## PO-7: Backend forged-POST guard remains intact

The server-side `_saveasnew` POST path must still reject users without add
permission.

Evidence: I6. Finding: F3.

Status: discharged by source inspection of `ModelAdmin._changeform_view()`.

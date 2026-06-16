# FVK Findings

Status: constructed, not machine-checked. Findings are derived from public
intent, Django source/docs, and symbolic case analysis only.

## F1: Pre-fix admin radio branch overwrote explicit labels

Input: blank `ForeignKey` in `radio_fields`, no custom widget, and an override
that sets `kwargs["empty_label"] = "I WANT TO SET MY OWN EMPTY LABEL"` before
calling `super().formfield_for_foreignkey()`.

Observed before V1: admin assigned `_("None")` in the radio branch and discarded
the caller's value.

Expected: the caller's `empty_label` takes precedence over the admin default.

Classification: code bug. This is the issue's reported behavior and is
discharged by PO1.

## F2: Truthiness fallback is too weak for the public ModelChoiceField contract

Input: blank `ForeignKey` in `radio_fields` with an explicit
`kwargs["empty_label"] = None` or an explicit empty-string label.

Observed under the issue's suggested `kwargs.get("empty_label") or _("None")`
shape: the explicit falsy value would be replaced by `_("None")`.

Expected: explicit `empty_label` values are meaningful. Django's forms docs say
`empty_label=None` disables the empty label entirely, so key presence should be
the precedence condition.

Classification: avoided code bug in the suggested repair. V1's
`kwargs.get("empty_label", _("None"))` discharges this.

## F3: Nonblank radio fields should continue suppressing the empty choice

Input: nonblank `ForeignKey` in `radio_fields`, with or without a supplied
`empty_label`.

Observed in V1: `empty_label` is set to `None`.

Expected: `ModelChoiceField` suppresses an empty choice for nonblank
`RadioSelect` fields; this is unchanged behavior and outside the reported
regression.

Classification: confirmed frame condition. Discharged by PO3.

## F4: No public compatibility break found

Input: documented `formfield_for_foreignkey(db_field, request, **kwargs)`
override that mutates `kwargs` and calls `super()`.

Observed in V1: method signature, dispatch, widget selection order, queryset
selection, and final `db_field.formfield(**kwargs)` call shape are unchanged.

Expected: existing public override patterns remain valid.

Classification: compatibility check passed. Discharged by PO5.

## F5: Proof is constructed only

Input: the FVK proof artifacts in `fvk/`.

Observed: commands to run `kompile`, `kast`, and `kprove` are recorded but not
executed, as required by the task.

Expected: no claim is described as machine-checked, and no tests are removed.

Classification: proof honesty condition. Reflected in PO7.

# Findings

Status: constructed, not machine-checked.

## FVK-F1: V1 missed radio widgets supplied by a custom form field class

Input class: `ForeignKey(blank=False)` with no explicit `widget` kwarg, no
explicit `empty_label`, and a custom `form_class` whose default `widget` is
`forms.RadioSelect`.

Observed in V1: `ForeignKey.formfield()` inspected only `kwargs['widget']`.
Because that key was absent, it did not set `empty_label=None`; later
`Field.__init__()` would still instantiate the form class's `RadioSelect`
default. The resulting radio field could therefore render the same blank option
the issue reports.

Expected: any effective `RadioSelect` widget for a non-blank foreign key should
suppress the generated empty label.

Status: fixed in V2 by falling back to
`getattr(kwargs.get('form_class', forms.ModelChoiceField), 'widget', None)` when
no explicit widget is supplied. Traced to PO1 and PO7.

## FVK-F2: Original root cause from the issue

Input class: `ForeignKey(null=True, blank=False)` rendered by a `ModelForm` with
`Meta.widgets = {'field': RadioSelect()}` and no initial related object.

Observed before the fix: `ModelChoiceField.empty_label` defaulted to
`"---------"`, `ModelChoiceIterator` yielded an empty choice, and
`RadioSelect` checked that choice because the empty form value formats to `''`.

Expected: no empty-value radio option and therefore no checked radio input for a
new form when blank is not a valid selection.

Status: fixed by setting `empty_label=None` for non-blank effective radio
widgets with no explicit `empty_label`. Traced to PO1, PO2, and PO3.

## FVK-F3: Explicit `empty_label` remains an accepted override

Input class: `ForeignKey(blank=False)`, effective radio widget, and explicit
`empty_label` supplied by the caller.

Observed in V2: the explicit `empty_label` is preserved, so a caller can still
create a blank radio choice deliberately.

Expected per this spec: explicit formfield kwargs override generated defaults.

Status: accepted compatibility behavior, not a code bug. Traced to PO6. If
Django wanted to forbid explicit blank radio choices for non-blank model fields,
that would be a separate public API policy change requiring stronger evidence
than the issue provides.

## FVK-F4: No test execution or machine verification

The task forbids running tests, Python, or K tooling. The proof is constructed
and the exact commands are recorded, but no `kprove` result is available.

Status: residual verification risk. Keep tests; do not remove or weaken any test
based on this constructed proof alone.

# Constructed Proof

Status: constructed, not machine-checked. Tests, Python, and K tooling were not
run.

## Claims Proved By Construction

The formal claims are in `fvk/foreignkey-formfield-spec.k` over the semantics in
`fvk/mini-django-formfield.k`.

The proof covers the `empty_label` defaulting decision inside
`ForeignKey.formfield()` and its direct effect on the rendered-choice mechanism.
There are no loops in the audited code path, so no circularity claim is needed.

## Symbolic Execution Sketch

Start with an in-domain call to `ForeignKey.formfield()` after V2:

1. The method rejects unresolved string related models exactly as before.
2. It reads `widget = kwargs.get('widget')`.
3. If `widget is None`, it reads the default widget from
   `kwargs.get('form_class', forms.ModelChoiceField).widget`. This models
   `Field.__init__()` choosing `widget or self.widget`.
4. It checks the guard:
   `not self.blank and 'empty_label' not in kwargs and widget is RadioSelect`.
   The radio predicate covers widget instances and widget classes/subclasses.
5. In the guard-true branch, it writes `kwargs['empty_label'] = None`.
6. It delegates to `super().formfield()` with the same `form_class`, `queryset`,
   `to_field_name`, and other kwargs as before.

The K semantics reduces these branches as follows:

- Non-blank explicit radio widget + no explicit `empty_label` reduces to
  `emptyNone`.
- Non-blank absent widget + radio form-class default + no explicit
  `empty_label` reduces to `emptyNone`.
- Blankable radio widget + no explicit `empty_label` reduces to `emptyDefault`.
- Non-radio widget + no explicit `empty_label` reduces to `emptyDefault`.
- Any explicit `empty_label` reduces to `emptyExplicit`.

## Connection To Rendering

Source inspection discharges the rendering side:

- `ModelChoiceIterator.__iter__()` yields the blank `("", empty_label)` choice
  if and only if `self.field.empty_label is not None`.
- `ChoiceWidget.format_value(None)` yields `['']` for single-choice widgets.
- `ChoiceWidget.optgroups()` marks an option selected when its string value is
  in that formatted value list.

Therefore, `emptyNone` implies no empty choice exists for `RadioSelect` to mark
checked on a new form. This establishes PO2 and PO3 for the reported observable.

## Adequacy Gate

`fvk/INTENT_SPEC.md`, `fvk/PUBLIC_EVIDENCE_LEDGER.md`,
`fvk/FORMAL_SPEC_ENGLISH.md`, `fvk/SPEC_AUDIT.md`, and
`fvk/PUBLIC_COMPATIBILITY_AUDIT.md` are present. All formal-English claims pass
against the intent spec. The V1 gap found by the adequacy pass is recorded as
FVK-F1 and fixed in V2.

## Test Redundancy

No test removal is recommended. The proof is constructed but not
machine-checked, and the task forbids modifying tests. Tests covering the
reported `Meta.widgets` case, widget-class case, custom form-class default
widget case, blankable radio case, select preservation, and explicit
`empty_label` preservation should be kept or added by maintainers.

## Reproduce The Machine Check Later

These commands were not run:

```sh
kompile fvk/mini-django-formfield.k --backend haskell
kast --backend haskell fvk/foreignkey-formfield-spec.k
kprove fvk/foreignkey-formfield-spec.k
```

Expected result: `#Top` for all claims.

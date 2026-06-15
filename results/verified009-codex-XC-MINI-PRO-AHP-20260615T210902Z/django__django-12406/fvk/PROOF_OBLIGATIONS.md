# Proof Obligations

Status: constructed, not machine-checked.

| ID | Obligation | Evidence | Disposition |
| --- | --- | --- | --- |
| PO1 | Non-blank `ForeignKey` + effective `RadioSelect` + no explicit `empty_label` must set `empty_label=None`. | E1, E3 | Discharged by V2 branch and K claims C1-C3. |
| PO2 | `empty_label=None` must remove the empty model-choice iterator member. | E5 | Discharged by source inspection of `ModelChoiceIterator.__iter__()`. |
| PO3 | With no empty iterator member, a new form's empty radio value must not check any radio input. | E4, E6 | Discharged by source inspection of `ChoiceWidget.format_value()` and `optgroups()`. |
| PO4 | `blank=True` radio fields may keep the empty label. | I4 | Discharged by guard `not self.blank` and K claim C4. |
| PO5 | Non-radio widgets, especially `Select`, keep Django's normal empty label. | E2 | Discharged by radio-widget predicate and K claim C5. |
| PO6 | Explicit caller-supplied `empty_label` is preserved. | E9 | Discharged by guard `'empty_label' not in kwargs` and K claim C6. |
| PO7 | "Effective `RadioSelect`" includes explicit widget classes, explicit widget instances/subclasses, and a radio default widget on a custom form field class. | E7, E8 | V1 only discharged explicit widgets. V2 discharges both explicit and form-class default paths. |
| PO8 | Public API and unrelated behavior are framed: signature, queryset, `to_field_name`, and explicit kwargs remain compatible. | E10 | Discharged by unchanged signature and unchanged `super().formfield()` arguments other than the generated default. |

## Machine-Check Commands Not Run

The task forbids running K tooling. These are the commands that would be used
later:

```sh
kompile fvk/mini-django-formfield.k --backend haskell
kast --backend haskell fvk/foreignkey-formfield-spec.k
kprove fvk/foreignkey-formfield-spec.k
```

Expected machine-check result: `#Top` for all claims.

# Formal Spec In English

The K model abstracts the audited code to a deterministic decision:

`decideEmptyLabel(blank, explicitWidget, formClassDefaultWidget, emptyLabelArg)`

It returns one of:

- `emptyNone`: `ForeignKey.formfield()` passes `empty_label=None`, so
  `ModelChoiceIterator` yields no empty choice.
- `emptyDefault`: no explicit `empty_label` is supplied and Django's normal
  default empty label remains available.
- `emptyExplicit`: the caller supplied `empty_label`, and that explicit value is
  preserved.

## Claims

C1. If `blank=False`, no explicit `empty_label` is supplied, and the explicit
widget is radio, the decision is `emptyNone`.

C2. The C1 radio abstraction covers widget classes, instances, and subclasses,
because the source predicate tests both `isinstance(widget, forms.RadioSelect)`
and `issubclass(widget, forms.RadioSelect)` for widget classes.

C3. If `blank=False`, no explicit `empty_label` is supplied, no explicit widget
is supplied, and the form field class default widget is radio, the decision is
`emptyNone`.

C4. If `blank=True` and no explicit `empty_label` is supplied, the decision is
`emptyDefault`, even for a radio widget.

C5. If `blank=False`, no explicit `empty_label` is supplied, and the effective
widget is an ordinary select, the decision is `emptyDefault`.

C6. If an explicit `empty_label` is supplied, the decision is `emptyExplicit`,
regardless of `blank` and widget kind.

C7. `emptyNone` implies no empty model-choice iterator member; without that
empty member, a new form whose value formats to `['']` has no blank radio option
to select.

C8. The public method signature and unrelated `ForeignKey.formfield()` defaults
are framed: queryset, `to_field_name`, and caller-provided keyword arguments
other than the generated `empty_label` default are preserved.

# Public Evidence Ledger

| ID | Source | Evidence | Semantic obligation | Status |
| --- | --- | --- | --- | --- |
| E1 | prompt | "ModelForm RadioSelect widget for foreign keys should not present a blank option if blank=False on the model" | Non-blank `ForeignKey` model-form radio fields must suppress the empty choice. | Encoded by PO1, PO2, PO7 and K claims C1-C3. |
| E2 | prompt | "Unlike the select widget, where a blank option is idiomatic even for required fields" | Do not remove the default blank option from ordinary select widgets. | Encoded by PO5 and K claim C5. |
| E3 | prompt | "`RadioSelect` has an inherent unfilled state" | Radio fields do not need an empty-value radio input to represent no selection. | Encoded by PO1 and PO3. |
| E4 | prompt | "there should be no checked option for RadioSelect's `<input>` tags when rendering a new form from a model if blank is not a valid selection" | Removing the empty choice must make the new-form empty value select no radio option. | Encoded by PO2 and PO3. |
| E5 | source | `ModelChoiceIterator.__iter__()` yields `("", self.field.empty_label)` only when `empty_label is not None`. | Setting `empty_label=None` removes the empty choice from model-choice iteration. | Encoded by PO2. |
| E6 | source | `ChoiceWidget.format_value(None)` yields `['']`, and `optgroups()` selects an option whose value string is in that list. | If the blank choice exists, the new form's empty value selects it; if it does not exist, no option is selected. | Encoded by PO3. |
| E7 | source | `fields_for_model()` passes `Meta.widgets[f.name]` as `kwargs['widget']`. | The reported `Meta.widgets = {'data_file': RadioSelect()}` path reaches `ForeignKey.formfield()` as an explicit widget. | Encoded by PO1 and C1. |
| E8 | source | `Field.__init__()` uses `widget or self.widget`; widget classes are instantiated and widget instances are deep-copied. | If no widget kwarg is supplied, the form field class default widget determines the actual widget. | Encoded by PO7 and C3. |
| E9 | source | `Field.formfield()` builds defaults and then `defaults.update(kwargs)`. Admin code explicitly avoids stomping on custom widget/choices arguments. | Explicit keyword arguments should override generated defaults, including `empty_label`. | Encoded by PO6 and C6. |
| E10 | source | `ForeignKey.formfield()` supplies `queryset`, `to_field_name`, and `form_class` to `super().formfield()`. | The fix must not alter queryset, target-field conversion, or the public method signature. | Encoded by PO8. |

## SUSPECT Legacy Evidence

The issue's rendered HTML includes a checked empty radio option. That output is
the reported bug, not an intended behavior. It is not used as a positive oracle
except to localize the old failure mechanism.

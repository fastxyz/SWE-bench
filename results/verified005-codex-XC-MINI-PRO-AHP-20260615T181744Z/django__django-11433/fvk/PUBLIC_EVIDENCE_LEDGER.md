# Public Evidence Ledger

| ID | Source | Evidence | Semantic obligation | Status |
| --- | --- | --- | --- | --- |
| E1 | prompt | "Allow `cleaned_data` to overwrite fields' default values." | Derived cleaned values must be assignment candidates despite model defaults. | Encoded in PO-1 and K claim `CI-DERIVED-NONEMPTY-ASSIGNS`. |
| E2 | prompt | "if 'some_field' isn't in the data payload ... value is derived from another field" | Payload omission alone cannot block a derived cleaned value. | Encoded in PO-1. |
| E3 | docstring | "`Construct and return a model instance from the bound form's cleaned_data`" | `cleaned_data` is the source of model instance values for eligible fields. | Encoded in SPEC and K claims. |
| E4 | public-test | "Empty data uses the model field default" for optional `mode` | Omitted field plus empty cleaned value preserves default. | Encoded in PO-2 and K claim `CI-OMITTED-EMPTY-PRESERVES-DEFAULT`. |
| E5 | public-test | "Blank data doesn't use the model field default" | Submitted blank value assigns empty value. | Encoded in PO-3 and K claim `CI-SUBMITTED-EMPTY-ASSIGNS`. |
| E6 | public-test | Checkbox and multiple-select empty data do not use the model default | Widgets that report "not omitted" bypass default preservation. | Encoded in PO-3. |
| E7 | implementation | `Field.save_form_data()` sets `setattr(instance, self.name, data)` | Assignment effect for non-file fields. | Modeled as `assign(name, value)`. |
| E8 | implementation | File fields are appended to `file_field_list` and saved after non-file fields | File assignment is delayed, not skipped, when the field passes the guard. | Encoded in PO-5 and K claim `CI-DERIVED-FILE-QUEUES`. |
| E9 | compatibility | No public evidence requests API changes | `construct_instance()` signature and hook calls must remain compatible. | Encoded in PO-7 and compatibility audit. |
| E10 | ambiguity | Public issue says "cleaned_data" broadly; public tests preserve normal omitted empty values | Explicit empty-value overrides are underspecified. | Recorded as F-003, not used to alter V1. |

# Public Evidence Ledger

Status: constructed, not machine-checked.

| ID | Source | Evidence | Semantic obligation | Status |
| --- | --- | --- | --- | --- |
| E1 | prompt | "DecimalField.to_python() raises TypeError on dict values." | Dict input is in the audited behavior space. Raw `TypeError` is the reported defect. | Encoded by `DICT-TYPEERROR-TO-VALIDATIONERROR` claim. |
| E2 | prompt | "produces TypeError instead of ValidationError" | Unsupported input rejected during decimal conversion must raise `ValidationError`. | Encoded by `dictInput` claim; V1 satisfies it. |
| E3 | prompt | "when you try to save a model object, and a decimal field got set to a dictionary by mistake" | The behavior must hold through model field conversion paths that call `to_python()`, not only direct unit calls. | Satisfied because `get_db_prep_save()` and `get_prep_value()` call the same `to_python()` method. |
| E4 | code docstring | `Field.to_python()` says it raises `django.core.exceptions.ValidationError if the data can't be converted.` | Conversion failures are validation failures at the model field API. | Encoded by invalid syntax, dict/type, and malformed/value claims. |
| E5 | public test | `test_decimalfield.py` checks `f.to_python(3) == Decimal('3')` and `f.to_python('3.14') == Decimal('3.14')`. | Valid non-float inputs continue to return converted decimal values. | Encoded by `validInput` claim. |
| E6 | public test | `test_decimalfield.py` checks float conversion honors `max_digits`. | Float path must remain separate and use field context. | Encoded by `floatInput` claim. |
| E7 | public test | `test_decimalfield.py` checks `'abc'` raises `ValidationError` with the invalid decimal message. | Existing `InvalidOperation` behavior must be preserved. | Encoded by `invalidSyntaxInput` claim. |
| E8 | adjacent code | `IntegerField.to_python()` and `FloatField.to_python()` catch `(TypeError, ValueError)` as invalid conversion input. | `ValueError` is a conversion-failure class consistent with neighboring numeric model fields. | Encoded by `malformedTupleInput` claim. |
| E9 | implementation | V1 changed only the exception tuple around `decimal.Decimal(value)`. | Valid returns, float branch, public signature, and other method wiring are frame conditions. | Reflected in compatibility audit and proof obligations. |

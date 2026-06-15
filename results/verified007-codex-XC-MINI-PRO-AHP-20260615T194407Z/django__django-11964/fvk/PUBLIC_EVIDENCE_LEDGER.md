# Public Evidence Ledger

Status: constructed, not machine-checked.

| ID | Source | Evidence | Semantic obligation | Status |
| --- | --- | --- | --- | --- |
| E1 | `benchmark/PROBLEM.md` | "The value of a TextChoices/IntegerChoices field has a differing type" | Audit both text and integer enum choice members used as model field values. | Encoded in `SPEC.md`, `choices-str-spec.k`, PO1-PO3. |
| E2 | `benchmark/PROBLEM.md` | `my_str_value = models.CharField(... choices=MyChoice.choices)` and `create(my_str_value=MyChoice.FIRST_CHOICE)` | The creation path where model storage contains an enum member is in scope. | Encoded as `CreateThenStr(Choice(...))`. |
| E3 | `benchmark/PROBLEM.md` | `self.assertEqual(str(my_object.my_str_value), "first")` | `str()` of a created field value must return the enum member's concrete value string. | Encoded as `CREATED-TEXTCHOICES-EXAMPLE`. |
| E4 | `benchmark/PROBLEM.md` | Retrieved test expects `str(my_object.my_str_value) == "first"` | Created and retrieved paths must agree on rendered output. | Encoded as `CREATED-CHOICE-STR` plus `RETRIEVED-PRIMITIVE-STR`. |
| E5 | `benchmark/PROBLEM.md` | Failure shows `'MyChoice.FIRST_CHOICE' != 'first'` | Enum-name stringification is the reported bug, not a behavior to preserve. | Finding F1; fixed by `Choices.__str__`. |
| E6 | Public hint in `benchmark/PROBLEM.md` | Created `__dict__` contains `<MyChoice.FIRST_CHOICE: 'first'>`; retrieved contains `'first'` | The model storage mismatch is explanatory evidence; the public observable still needs matching string output. | Supports choosing enum stringification rather than ORM assignment coercion. |
| E7 | `repo/docs/ref/models/fields.txt` | "Enum member values are a tuple of arguments to use when constructing the concrete data type" and `.value` is documented | The concrete `.value` is the intended field-compatible value for enum members. | Encoded as `valueText(V)`. |
| E8 | `repo/tests/model_enums/tests.py` | Tests assert `repr(...)`, `.label`, `.value`, `.choices`, `.labels`, `.values`, `.names` | These enum APIs are frame conditions. | Encoded in PO4/PO5 and compatibility audit. |
| E9 | `repo/tests/model_fields/test_charfield.py` | Public test refreshes a model created with `TextChoices` and compares primitive values | Database preparation/retrieval already produce primitive-compatible values. | Supports rejecting field-preparation changes. |
| E10 | `reports/baseline_notes.md` | V1 changed only `Choices.__str__` | Candidate implementation evidence: check whether the minimal change discharges E1-E8. | Audited in `PROOF.md` and `FINDINGS.md`. |

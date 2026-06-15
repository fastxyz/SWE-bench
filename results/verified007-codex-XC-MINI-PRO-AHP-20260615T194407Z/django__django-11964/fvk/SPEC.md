# FVK Spec

Status: constructed, not machine-checked.

## Scope

This FVK pass audits the V1 fix for `django__django-11964`: `Choices.__str__()` in `repo/django/db/models/enums.py`.

The modeled observable is:

- a model field value on the creation path stores a `TextChoices` or `IntegerChoices` enum member;
- a model field value on the retrieval path stores the primitive concrete value;
- `str(field_value)` must render the same concrete-value text on both paths.

The spec intentionally does not require assignment-time coercion of model `__dict__` values. The public hint identifies the storage mismatch as explanatory evidence, while the failing assertion and external API concern identify `str(field_value)` as the observable defect.

## Public Intent Ledger

See `fvk/PUBLIC_EVIDENCE_LEDGER.md` for the standalone ledger. Critical entries:

- E3: the public failing test requires `str(my_object.my_str_value) == "first"` for a freshly created object.
- E4: the retrieved path already produces the same string output from primitive storage.
- E5: enum-name stringification (`"MyChoice.FIRST_CHOICE"`) is the bug symptom.
- E7: Django docs expose enum member `.value` as the concrete field-compatible value.
- E8: public enum tests require `repr()`, labels, values, choices, and lookup behavior to remain intact.

## Contract

For every modeled `TextChoices` or `IntegerChoices` member with concrete value `V`:

1. `str(created_field_value_storing(member)) == str(V)`.
2. `str(retrieved_field_value_storing(V)) == str(V)`.
3. Therefore, created and retrieved field values have equal string-rendered external output.
4. For the public example, `str(MyChoice.FIRST_CHOICE) == "first"`.
5. Enum metadata and representation APIs not involved in `str()` are preserved.

## Formal Model

`fvk/mini-python-enum.k` models only the constructs needed for the observable:

- `Choice(NAME, V)` for an enum member;
- `Created(Choice(NAME, V))` for a freshly created model field storing an enum member;
- `Retrieved(V)` for a database-retrieved field storing the primitive value;
- `StrOf(...)` for Python string conversion;
- `valueText(V)` for the primitive value's string-rendered text.

`fvk/choices-str-spec.k` contains the K claims:

- `CREATED-CHOICE-STR`: `CreateThenStr(Choice(NAME, V)) => valueText(V)`.
- `RETRIEVED-PRIMITIVE-STR`: `RetrieveThenStr(V) => valueText(V)`.
- `CREATED-RETRIEVED-EQUIVALENCE`: `CreatedRetrievedTexts(Choice(NAME, V)) => pair(valueText(V), valueText(V))`.
- `CREATED-TEXTCHOICES-EXAMPLE`: `CreateThenStr(Choice("FIRST_CHOICE", SVal("first"))) => text("first")`.
- `REPR-FRAME`: `ReprOf(Choice(NAME, V)) => enumText(NAME)`.

## Implementation Correspondence

V1 code:

```python
def __str__(self):
    return str(self.value)
```

This corresponds to the formal transition:

```k
rule <k> StrOf(Created(Choice(NAME:String, V:Value))) => valueText(V) ... </k>
```

The transition removes the legacy enum-name `str()` output while leaving enum member identity, `.value`, `.label`, choices metadata, and `repr()` outside the modified behavior.

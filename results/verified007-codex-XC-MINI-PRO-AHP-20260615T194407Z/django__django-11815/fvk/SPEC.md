# FVK Spec: Enum Migration Serialization

Status: constructed, not machine-checked.

## Target

The audited unit is `EnumSerializer.serialize()` in
`repo/django/db/migrations/serializer.py`.

Observable result: a pair `(serialized_expression, imports)` returned to
`MigrationWriter.serialize()`.

## Intent-Only Specification

For a named, importable Python `enum.Enum` member handled by
`EnumSerializer`, migration serialization must reconstruct the member by its
stable enum member name, not by serializing the member value. For member
`E = Module.EnumClass.MEMBER`, with `E.name == "MEMBER"` and arbitrary
`E.value`, the serialized expression must be:

```python
Module.EnumClass['MEMBER']
```

The import set must be sufficient for that expression, namely the enum class
module import. The expression must not depend on `E.value`, because enum values
may be lazy translation objects whose rendered string can change with the active
language.

## Public Evidence Ledger

| ID | Source | Evidence | Semantic obligation | Status |
| --- | --- | --- | --- | --- |
| E1 | problem title | "Migrations uses value of enum object instead of its name." | The serializer must not emit a value-constructor expression for ordinary enum members. | Encoded by PO2. |
| E2 | problem example | Current generated code: `Status('Good')`; desired code: `Status['GOOD']`. | Output form is bracket lookup by enum member name. | Encoded by PO2 and PO4. |
| E3 | problem description | Value is translated, then old migrations raise `ValueError`. | Serialized expression must be independent of translated/lazy enum values. | Encoded by PO3. |
| E4 | public hint | "we should use a name property" | The member identifier comes from `self.value.name`. | Encoded by PO2. |
| E5 | source registry | `models.Choices` is registered before `enum.Enum`. | `ChoicesSerializer` remains a separate value serializer and is not part of this repair. | Encoded by PO1 and PO6. |
| E6 | public tests | `test_serialize_enums()` expects `TextEnum('a-value')`. | These expectations encode the reported legacy behavior and are SUSPECT for this issue. | Recorded as F2. |

## Domain and Preconditions

- `self.value` is a named enum member dispatched to `EnumSerializer`.
- The enum class is importable by the existing serializer convention:
  `enum_class.__module__` plus `enum_class.__name__`.
- `self.value.name` is a stable string key for the member in the enum class.
- `models.Choices` members are outside this unit because the registry dispatches
  them to `ChoicesSerializer` before `EnumSerializer`.

The preconditions match the public issue's named-member example and the existing
migration serializer import convention. Pseudo-members without a stable enum
member name are not specified by the public issue.

## Formal Contract

Let:

- `M = self.value.__class__.__module__`
- `C = self.value.__class__.__name__`
- `N = self.value.name`
- `V = self.value.value`

Claim `ENUM-SERIALIZE`:

```text
serializeEnum(enumMember(M, C, N, V))
  reaches
serializeResult(M + "." + C + "[" + repr(N) + "]", {"import " + M})
```

Side condition: `N` is non-empty and denotes the named enum member.

The constructed K-style artifacts are in:

- `fvk/mini-python-enum-serializer.k`
- `fvk/enum-serializer-spec.k`

## Adequacy Audit

The formal claim says exactly that enum serialization uses `name`, not `value`,
and returns only the module import needed by the generated expression. This
matches E1-E4. It does not claim behavior for `models.Choices`; that omission is
intentional and matches E5. Existing public tests that assert value-constructor
output conflict with E1-E4 and are therefore treated as SUSPECT evidence rather
than specification.

## Compatibility Audit

`EnumSerializer.serialize()` keeps the same public method signature and return
shape: `(string, imports)`. The generated expression remains a Python expression
using the imported module and enum class. No writer API, registry API, field API,
or migration operation API changes.

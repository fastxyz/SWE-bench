# FVK Findings

Status: constructed, not machine-checked.

## F1: Value-Based Enum Serialization Violates Public Intent

Classification: code bug, resolved by V1.

Input:

```python
class Status(Enum):
    GOOD = _("Good")

default = Status.GOOD
```

Observed before V1:

```python
Status('Good')
```

Expected from public intent:

```python
Status['GOOD']
```

Reasoning: The problem statement identifies value-based reconstruction as the
bug because the value can be translated before an old migration is imported.
The V1 code emits `self.value.name`, so this finding is resolved for named enum
members.

Proof obligations: PO2, PO3, PO4.

## F2: Existing Public Enum Serializer Tests Encode Legacy Behavior

Classification: suspect public-test evidence, not a production-code blocker.

Input:

```python
TextEnum.A
```

Observed public test expectation:

```python
migrations.test_writer.TextEnum('a-value')
```

Expected from public issue intent:

```python
migrations.test_writer.TextEnum['A']
```

Reasoning: The FVK intent-evidence rules mark tests that assert the issue's
reported buggy behavior as SUSPECT. These tests should be updated in a normal
test-maintenance pass, but this benchmark forbids modifying test files.

Proof obligations: PO2, PO6, PO8.

## F3: `models.Choices` Is a Separate Serialization Path

Classification: no code bug found.

Input:

```python
class TextChoices(models.TextChoices):
    A = "A", "A value"
```

Observed and expected:

```python
MigrationWriter.serialize(TextChoices.A) == ("'A'", set())
```

Reasoning: `models.Choices` is registered before `enum.Enum`, so its members use
`ChoicesSerializer`, which serializes the underlying database value. The public
issue targets ordinary enum object defaults, not Django choices values.

Proof obligations: PO1, PO6.

## F4: No Value Import Is Required After Name-Based Serialization

Classification: no code bug found.

Input:

```python
class DecimalEnum(Enum):
    A = Decimal("1.0")
```

Expected:

```python
DecimalEnum['A']
```

Reasoning: Once the generated expression no longer mentions the enum value,
imports needed only to construct that value are unnecessary. The module import
for the enum class is sufficient for the serialized expression.

Proof obligations: PO3, PO5.

## F5: Constructed Proof Not Machine-Checked

Classification: proof status limitation.

No tests, Python code, `kompile`, `kast`, or `kprove` were run. The proof
artifacts are a constructed audit only. Test removal is not recommended unless
the emitted proof commands are run later and discharge to `#Top`.

Proof obligations: PO8.

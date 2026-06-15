# FVK Findings

Status: constructed, not machine-checked.

## Findings From Formalization

### F1: Freshly created `TextChoices` field values used enum-name stringification

- Input: a created model instance whose `CharField` stores `MyChoice.FIRST_CHOICE` with `.value == "first"`.
- Observed before V1: `str(my_object.my_str_value) == "MyChoice.FIRST_CHOICE"` per the public failure.
- Expected: `str(my_object.my_str_value) == "first"`.
- Classification: code bug.
- Public evidence: ledger E2-E5.
- Status: resolved by V1. `Choices.__str__()` now returns `str(self.value)`.

### F2: The same family obligation applies to `IntegerChoices`

- Input: a created model instance whose `IntegerField` stores an `IntegerChoices` member with concrete value `1`.
- Observed risk: enum default stringification can expose the enum member name rather than the concrete integer value's text.
- Expected: string conversion matches the primitive integer value's string conversion.
- Classification: family completeness obligation from the issue title.
- Public evidence: ledger E1, E7.
- Status: resolved by placing the method on `Choices`, covering `IntegerChoices`.

### F3: Assignment-time primitive coercion is not required by public intent

- Input: created instance storage contains an enum member, retrieved instance storage contains a primitive value.
- Observed: the public hint shows differing `__dict__` storage.
- Expected: the public tests and API concern require matching `str(field_value)`, not identical storage type.
- Classification: rejected alternative, not a code bug after V1.
- Public evidence: ledger E3-E6.
- Status: no source change. Broad descriptor or model-initialization coercion would alter ORM assignment semantics beyond the stated observable.

### F4: Base-class `Choices.__str__` affects custom concrete `Choices` subclasses

- Input: a custom concrete subclass such as `class MoonLandings(datetime.date, models.Choices)`.
- Observed after V1: `str(member)` delegates to `str(member.value)`.
- Expected: public docs do not require legacy enum-name stringification; docs describe `.value` as the concrete data type value.
- Classification: compatibility observation.
- Public evidence: ledger E7-E8 and `PUBLIC_COMPATIBILITY_AUDIT.md`.
- Status: accepted. The uniform base-class implementation preserves public enum metadata and avoids duplicating identical behavior in `TextChoices` and `IntegerChoices`.

## Proof-Derived Findings From `/verify`

No blocking proof-derived findings were found.

- The formal claims cover the full public observable: created string output, retrieved string output, their equivalence, the concrete `"first"` example, and `repr()` frame behavior.
- No claim preserves the legacy enum-name `str()` output.
- No hidden test, benchmark verdict, gold patch, or external source was used.
- The proof is constructed only; `kompile`/`kprove` were not run.

## Test Guidance

Recommended tests to add or keep in the fixed suite, without editing tests in this task:

- Add/keep a `TextChoices` created-instance assertion: `str(obj.field) == "first"`.
- Add/keep a retrieved-instance assertion for the same value.
- Add/keep an `IntegerChoices` created-instance assertion that `str(obj.field)` matches the primitive integer value text.
- Keep enum metadata tests for `.choices`, `.labels`, `.values`, `.names`, `.label`, `.value`, lookup, and `repr()`.

No test removal is recommended unless the K claims are machine-checked and the project owner chooses to remove redundant point tests.

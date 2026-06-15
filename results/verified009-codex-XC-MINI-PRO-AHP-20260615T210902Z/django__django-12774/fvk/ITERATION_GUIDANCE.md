# FVK Iteration Guidance

Status: constructed, not machine-checked.

## Code Guidance

V2 should stand. The FVK audit found and resolved one small V1 completeness gap:
the uniqueness check now compares a qualifying one-field constraint identifier
against both `field.name` and `field.attname`.

No further production-code change is justified by the public intent. In
particular:

- Do not accept composite `UniqueConstraint`s for a single `field_name`.
- Do not accept conditional `UniqueConstraint`s.
- Do not change batching, filtering, ordering reset, or dictionary
  construction.
- Do not modify tests in this benchmark task.

## Suggested Future Tests

The fixed project test suite is hidden and must not be edited here. For a
normal development branch, useful public tests would be:

- `in_bulk(field_name="slug")` accepts a model with
  `UniqueConstraint(fields=["slug"], condition=None)`.
- `in_bulk(field_name="author_id")` accepts a relation field covered by a
  one-field total constraint declared with either `author` or `author_id`.
- `in_bulk(field_name="slug")` still rejects
  `UniqueConstraint(fields=["slug", "site"])`.
- `in_bulk(field_name="slug")` still rejects a conditional unique constraint.

## Residual Risk

The FVK proof is constructed, not machine-checked. It verifies the validation
decision with a small model, not full Django ORM/database semantics. That is
adequate for this source edit because the changed code only affects the
validation predicate; existing query execution behavior is a frame condition.

Run the recorded K commands in a proper K environment before treating the proof
as machine-verified or removing any tests.

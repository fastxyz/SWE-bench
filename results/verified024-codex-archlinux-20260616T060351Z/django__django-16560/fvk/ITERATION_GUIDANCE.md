# Iteration Guidance

Status: constructed, not machine-checked.

## V2 decision

V1 stands as the V2 source fix. The FVK audit found no source-code change needed
after applying the proof obligations in `PROOF_OBLIGATIONS.md`.

## Decisions tied to findings

- Keep `CheckConstraint`, expression `UniqueConstraint`, conditional
  `UniqueConstraint`, and `ExclusionConstraint` code propagation as implemented:
  justified by F-001 and PO-4 through PO-6.
- Keep deconstruction/clone preservation as implemented: justified by F-002 and
  PO-3.
- Keep field-only `UniqueConstraint` without condition on the legacy
  `unique_error_message()` path: justified by F-003 and PO-5.
- Keep existing default behavior for omitted codes: justified by F-004 and PO-2.
- Do not edit tests: explicitly forbidden by the task.

## Suggested public tests for a normal development environment

These are recommendations only; no tests were edited or run.

- `BaseConstraint(..., violation_error_code="custom")` stores the code,
  deconstructs with the kwarg, and clones with the code preserved.
- `CheckConstraint.validate()` raises `ValidationError` with the custom code.
- Expression and conditional `UniqueConstraint.validate()` raise with the custom
  code.
- PostgreSQL `ExclusionConstraint.validate()` raises with the custom code.
- Constraints that differ only by `violation_error_code` compare unequal and show
  the code in `repr()`.
- Field-only `UniqueConstraint` without condition continues using the legacy
  unique error path.

## Follow-up outside this source-code repair

F-005 records that docs signatures still omit `violation_error_code`. In a full
Django contribution, update the docs and release notes alongside the source
change. That follow-up is separate from the benchmark repair and was not applied
here.


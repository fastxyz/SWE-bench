# Iteration Guidance

Status: constructed, not machine-checked.

## V2 decision

V1 stands unchanged. The audit found no additional source change justified by
public intent or proof obligations.

## Decision trace

- Keep the V1 marker assignment in `ChoicesMeta.__new__()`: justified by
  F-001 and PO-001 through PO-003.
- Do not edit `django/template/base.py`: justified by F-002 and PO-002, because
  the resolver already implements the required marker behavior.
- Do not move the marker into the `Choices` class body: rejected by F-003 and
  PO-004, because enum class-body assignments risk becoming enum members.
- Do not broaden the change to non-Django enum classes: the public issue and
  E-004 target the `Choices` family, and PO-005 preserves resolver behavior for
  other callables.

## Suggested future checks

When an execution environment is available, run the recorded K commands and the
relevant Django template/model enum tests. Useful public tests to add or keep
would cover:

- `models.TextChoices` in a template dotted lookup;
- `models.IntegerChoices` in a template dotted lookup;
- a functional-API choices class in a template dotted lookup;
- preservation of existing `choices`, `labels`, `values`, and `names` behavior.

No test files should be modified in this benchmark task.

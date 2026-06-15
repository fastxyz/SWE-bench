# Public Compatibility Audit

## Changed symbol

- `django.db.models.expressions.ExpressionWrapper.get_group_by_cols`

## Signature

- Before V1: inherited `BaseExpression.get_group_by_cols(self, alias=None)`.
- V2: defines `get_group_by_cols(self, alias=None)`.
- Compatibility result: pass. The public call signature is unchanged.

## Callers

- `Query.set_group_by()` can call annotations with `alias=alias`.
- `SQLCompiler.get_group_by()` can call selected expressions without `alias`.
- Other expression classes call child `get_group_by_cols()` mostly without
  `alias`.

Compatibility result: pass. V2 supports both no-argument and `alias=...` calls.

## Custom child overrides

Public deprecation evidence shows custom expressions may still define
`get_group_by_cols(self)` without `alias`. V1 would forward `alias` through the
wrapper and risk `TypeError`. V2 checks the child signature, emits
`RemovedInDjango40Warning`, and calls without the keyword.

Compatibility result: pass.

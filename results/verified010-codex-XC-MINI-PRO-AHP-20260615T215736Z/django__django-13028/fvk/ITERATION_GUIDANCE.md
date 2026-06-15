# FVK Iteration Guidance

Status: constructed, not machine-checked.

## Decision

V1 was directionally correct but incomplete at the expression-protocol boundary
identified by F-02. V2 refines the fix by returning immediately from
`check_filterable()` for any object that lacks `resolve_expression`.

## Code Change Applied

File: `repo/django/db/models/sql/query.py`

Change: add an early return at the start of `check_filterable()`:

```python
if not hasattr(expression, 'resolve_expression'):
    return
```

Justification: PO-01 requires ordinary RHS values to be outside the expression
filterability contract. F-02 showed that V1 still allowed a non-expression RHS
with an unrelated `get_source_expressions` method to be walked as an expression
container. The early return fixes both the original collision and that
proof-derived boundary issue.

## What To Test Later

When an execution environment is available, add or rely on tests for:

- A foreign key lookup whose RHS model instance has `filterable=False` and no
  `resolve_expression`; it must not raise `NotSupportedError`.
- A real ORM expression with `filterable=False`; it must still raise
  `NotSupportedError` in a filter clause.
- A filterable expression whose source expression is non-filterable; recursive
  validation must still reject it.

No test files were edited in this benchmark.

## Machine-Check Commands For Later

```sh
cd fvk
kompile mini-django-query.k --backend haskell
kast --backend haskell query-filterable-spec.k
kprove query-filterable-spec.k
```

Expected result after a real machine check: `kprove` should return `#Top` for
the abstract claims. Until that is run, the proof remains constructed, not
machine-checked.

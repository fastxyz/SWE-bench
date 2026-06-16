# Iteration Guidance

Status: constructed for FVK audit, not machine-checked.

## Code Decision

V1 stands unchanged. The FVK audit found that the V1 source edit directly
discharges the missing alias obligation:

```python
elif parts[0] in ('return', 'returns'):
    has_description.add('return')
```

This satisfies `PO-2` and enables `PO-3` for Napoleon-generated `returns` fields.

## Rejected Changes

- Do not change Napoleon to emit `:return:`. Finding `F-2` shows that
  `:returns:` is valid domain syntax and already emitted by Napoleon.
- Do not change the `"all"` branch. Finding `F-3` shows that branch already adds
  missing return types without requiring a documented return description.
- Do not modify public APIs or hooks. `PO-8` and the compatibility audit show no
  API change is needed.

## Recommended Future Test

When test files are editable, add a regression test where
`autodoc_typehints = "description"`,
`autodoc_typehints_description_target = "documented"`, and the field list
contains `:returns:` with a function return annotation. The expected output should
include the return type.

## Residual Risk

The FVK proof is constructed, not machine-checked. Keep existing tests until the
recorded K commands are run and return `#Top`.

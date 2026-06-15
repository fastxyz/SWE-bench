# FVK Notes

## Decision

The FVK audit found that V1 fixed the reported `filterable=False` collision but
left one expression-protocol boundary incomplete. I revised the source to V2 by
adding an early return for values that do not expose `resolve_expression`.

## Code change

Changed `repo/django/db/models/sql/query.py`.

The new first branch in `check_filterable()` is:

```python
if not hasattr(expression, 'resolve_expression'):
    return
```

Trace:

- `fvk/FINDINGS.md` F-01 shows the original bug: ordinary RHS model instances
  with `filterable=False` were rejected as expressions.
- `fvk/FINDINGS.md` F-02 shows the V1 audit issue: non-expression RHS values
  could still be walked via an unrelated `get_source_expressions()` method.
- `fvk/PROOF_OBLIGATIONS.md` PO-01 requires non-expression RHS values to return
  before inspecting either `filterable` or source-expression metadata.

## Behavior kept from V1

The existing `filterable=False` rejection for real expressions remains after the
new early return.

Trace:

- `fvk/FINDINGS.md` F-03 records the preservation requirement.
- `fvk/PROOF_OBLIGATIONS.md` PO-02 requires real expression objects with
  `filterable=False` to continue raising `NotSupportedError`.

The recursive source-expression walk remains in place for real expressions.

Trace:

- `fvk/FINDINGS.md` F-04 records this preservation requirement.
- `fvk/PROOF_OBLIGATIONS.md` PO-03 requires recursive validation of real
  expression sources.

## Verification boundary

No tests, Python, or K tooling were run. The FVK proof is constructed, not
machine-checked, as required by `fvk/FINDINGS.md` F-05 and
`fvk/PROOF_OBLIGATIONS.md` PO-06. No test files were modified.

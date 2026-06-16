# Iteration Guidance

Status: V1 stands unchanged.

## Decision

Keep the V1 source change:

```python
prec = max(1, abs(p) + units + 1)
```

## Why

- F-01 is the reported bug and is resolved by PO-02 and PO-03.
- F-02 confirms that the edit is framed: when the old precision was already
  valid, `max(1, raw)` preserves it exactly.
- PO-05 confirms the negative-precision zero path remains unchanged.
- PO-06 confirms there is no public API or callsite compatibility issue.

## No Additional Source Edits

The FVK audit did not find another source change justified by the public issue
and proof obligations. F-03 is a proof capability boundary, not a code defect.
F-04 is a test recommendation, but this benchmark forbids modifying tests.

## Next Conventional Checks

In an environment where execution is allowed, run the normal Django
`floatformat` tests and add regression coverage for:

- `floatformat("0.00", 0) == "0"`
- `floatformat(Decimal("0.00"), 0) == "0"`

In an environment with K installed, run the commands recorded in `fvk/PROOF.md`
to upgrade the FVK result from constructed to machine-checked.

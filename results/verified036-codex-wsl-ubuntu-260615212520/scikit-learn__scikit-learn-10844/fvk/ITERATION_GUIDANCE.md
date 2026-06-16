# FVK ITERATION GUIDANCE

Status: V1 stands unchanged.

## Decision

Keep the V1 source expression:

```python
np.sqrt(tk / pk) * np.sqrt(tk / qk) if tk != 0. else 0.
```

Rationale:

- F-1 identifies the actual defect as the integer product `pk * qk`.
- PO-4 proves the V1 expression is algebraically equivalent to the public FMI
  formula on the nonzero valid-count path.
- PO-5 proves the V1 expression avoids the reported overflowing integer
  product rather than merely widening it.
- F-2 and PO-3 discharge the denominator-safety concern.
- F-3 and PO-2 preserve the zero boundary.

## Rejected Alternatives

- `pk.astype(np.int64) * qk.astype(np.int64)`: rejected because PO-5 requires
  eliminating the overflowing product, not only raising the threshold.
- `float(pk) * qk` inside the original formula: rejected because V1 is the
  public issue proposal and avoids the large denominator product completely.
- Log-space calculation: rejected as a larger numerical-policy change than the
  proof obligations require.

## Recommended Follow-Up Outside This Patch

- In a real development environment, run the emitted K commands and the
  project's clustering metric tests. This task forbids doing so here.
- If future work targets platform-specific dtype overflow earlier in count
  construction, write a separate proof obligation for the `tk`, `pk`, and `qk`
  reductions rather than folding that concern into the denominator fix.
- Add or keep a regression test with large valid counts/labels that previously
  caused the denominator product to overflow. Do not edit tests in this task.

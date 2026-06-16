# Iteration Guidance

Status: V1 stands unchanged after FVK audit.

## Decision

Keep the V1 source edit:

```
m12 = 2*s*(q.c*q.d - q.b*q.a)
```

No additional production-code edits are justified by the public issue and the
proof obligations.

## Why No Further Source Change

- F1 and PO2-PO3 prove the reported x-axis defect is exactly the `M12` sign.
- PO4 shows the existing documented z-axis convention is preserved, so no
  broader active/passive convention change is needed.
- PO5 shows the corrected sign is consistent with `from_rotation_matrix()`.
- F2 identifies visible tests that encode the legacy behavior, but the task
  forbids test edits and those tests are evidence of the old bug rather than a
  reason to revert the source fix.
- F3 records the zero-quaternion boundary. This FVK spec excludes it because a
  zero quaternion does not represent a rotation; adding a new guard would be an
  API-hardening change beyond the reported issue.

## Recommended Future Work

- Add or update tests, when allowed, for the x-axis case from the issue:
  `Quaternion(cos(x/2), sin(x/2), 0, 0)`.
- Update any legacy expectations for general quaternions, including
  `Quaternion(1, 2, 3, 4)`, so `M12 = 2/3` and the dependent 4x4 translation
  entry is `0`.
- Consider documenting or guarding the nonzero-quaternion precondition in a
  separate compatibility-aware change.
- Run the emitted K commands in an environment with K installed before using
  the proof to remove or weaken tests.

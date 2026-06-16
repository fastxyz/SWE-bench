# ITERATION_GUIDANCE

Status: V1 stands. No V2 source edit is required.

## Decision

Keep the current production source change:

```python
del cls.class_lookups[lookup_name]
cls._clear_cached_lookups()
```

This is justified by FINDINGS F-001 and F-002 and by PROOF_OBLIGATIONS O-002,
O-003, O-004, and O-006.

## Guidance for This Patch

- Do not add caller-side cache clearing. The method that mutates
  `class_lookups` should own the invalidation. See F-003 and O-007.
- Do not change missing-key behavior to an idempotent no-op. That would be a
  separate API change outside the prompt-derived intent. See F-004 and O-005.
- Do not reduce cache clearing to `cls` only. Subclass caches can inherit
  lookup entries from `cls`. See F-002 and O-006.
- Do not modify tests in this task. The fixed test suite is hidden and public
  tests are read-only by instruction.

## Future Work Outside This Task

- Add or update a public test that demonstrates a lookup remains visible from a
  cached `get_lookups()` result after V0 unregister, then disappears after V1
  unregister.
- Simplify public tests that manually call `_clear_cached_lookups()` after
  `_unregister_lookup()`, after confirming the new behavior under the project
  test runner.
- Machine-check the K claims with the commands in `PROOF.md` before treating
  any test as proof-subsumed.


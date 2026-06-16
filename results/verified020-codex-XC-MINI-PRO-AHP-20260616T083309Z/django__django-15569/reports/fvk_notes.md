# FVK Notes

## Decision Summary

V1 stands unchanged. The audit confirmed that the source edit in
`repo/django/db/models/query_utils.py` satisfies the prompt-derived cache
invalidation requirement:

```python
del cls.class_lookups[lookup_name]
cls._clear_cached_lookups()
```

No tests, Python, or K tooling were run.

## Trace to Findings and Proof Obligations

### Keep `cls._clear_cached_lookups()` in `_unregister_lookup()`

Decision: keep the V1 source edit.

Reasoning: FINDINGS F-001 identifies the original stale-cache bug:
unregistering removed the registry entry but left cached lookup maps able to
return the removed lookup. PROOF_OBLIGATIONS O-002, O-003, and O-004 require
registry deletion, descendant-inclusive cache invalidation, and recomputation
from the current registry. V1 satisfies those obligations by deleting the
lookup entry and immediately calling `_clear_cached_lookups()`.

### Keep the descendant-inclusive clear scope

Decision: do not replace `_clear_cached_lookups()` with a direct
`cls.get_lookups.cache_clear()`.

Reasoning: FINDINGS F-002 shows that subclass caches can include lookup entries
inherited from `cls`. PROOF_OBLIGATIONS O-003 and O-006 require invalidating
`cls` and subclasses. `_clear_cached_lookups()` is the existing helper that
implements that scope.

### Do not add caller-side fixes

Decision: no source changes in `django.test.utils.register_lookup()` or
`django.contrib.postgres.apps`.

Reasoning: FINDINGS F-003 and F-005 show that callers are compatible with the
same `_unregister_lookup()` signature and should not have to perform cache
cleanup themselves. PROOF_OBLIGATION O-007 requires caller compatibility and
method-owned invalidation.

### Do not make unregister idempotent

Decision: do not catch `KeyError` or make missing lookups a no-op.

Reasoning: FINDINGS F-004 classifies absent lookup entries as outside the
normal-success domain. PROOF_OBLIGATIONS O-001 and O-005 preserve the existing
successful-delete precondition and missing-key behavior because the public issue
only requires cache clearing after an unregister mutation.

### Do not edit tests

Decision: no test files were modified.

Reasoning: the task forbids modifying tests. FINDINGS F-003 records that one
public test's manual `_clear_cached_lookups()` call is now redundant, but that
is future cleanup guidance, not part of this production-code fix.

## FVK Artifact Decisions

The FVK package includes the five requested artifacts:

- `fvk/SPEC.md`
- `fvk/FINDINGS.md`
- `fvk/PROOF_OBLIGATIONS.md`
- `fvk/PROOF.md`
- `fvk/ITERATION_GUIDANCE.md`

It also includes the additional adequacy and formal-core artifacts required by
the FVK method:

- `fvk/INTENT_SPEC.md`
- `fvk/PUBLIC_EVIDENCE_LEDGER.md`
- `fvk/FORMAL_SPEC_ENGLISH.md`
- `fvk/SPEC_AUDIT.md`
- `fvk/PUBLIC_COMPATIBILITY_AUDIT.md`
- `fvk/mini-lookup-cache.k`
- `fvk/register-lookup-spec.k`

The proof is constructed, not machine-checked. The commands to check it later
are recorded in `fvk/PROOF.md`.


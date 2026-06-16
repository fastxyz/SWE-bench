# FVK Notes

## Decision Summary

The FVK audit confirms that V1 stands unchanged. No additional source edit is
justified by the scoped spec and proof obligations.

## Source Decisions

1. Kept the V1 predicate in `repo/django/db/models/query.py`:

   ```python
   if not hasattr(attr, 'resolve_expression'):
       attr = Value(attr, output_field=field)
   ```

   Reason: Finding F-001 identifies the pre-fix bug as literalizing plain `F()`
   values, and PO-1 through PO-3 require `F()` and other expression-like values
   to pass through for downstream resolution. PO-2 specifically requires the
   branch predicate to use `resolve_expression`, not `Expression` subclassing.

2. Kept the literal-value behavior unchanged.

   Reason: Finding F-002 says V1 matches the scoped contract for both value
   families. PO-4 requires values without `resolve_expression` to continue being
   wrapped in `Value(attr, output_field=field)`.

3. Kept batching, field/object loop construction, `Case`/`When` construction,
   optional casting, transaction handling, and row-count accumulation unchanged.

   Reason: PO-5 frames those behaviors as unchanged source-loop obligations.
   Finding F-002 found no proof-derived code bug outside the normalization
   predicate.

4. Kept the public API unchanged.

   Reason: PO-6 and `fvk/PUBLIC_COMPATIBILITY_AUDIT.md` find no signature,
   return-type, callsite, or virtual-dispatch compatibility issue. The local
   removal of the unused `Expression` import does not affect public API.

5. Did not modify tests or run tests/K/Python.

   Reason: Finding F-003 and PO-7 record the honesty gate and the task's
   constraints. The artifacts include commands for future machine checking, but
   they were not executed here.

## Rejected Alternatives

- `isinstance(attr, (Expression, F))` was rejected because it only satisfies the
  concrete witness in F-001 and does not satisfy PO-2's expression-protocol
  obligation. Finding F-002 records this as narrower than the public hint.
- Adding an extra wrapper around `F()` was rejected because PO-3 is already
  discharged by preserving expression-like values through `When`/`Case` and the
  existing update resolver.

## Artifacts Produced

Required task artifacts:

- `fvk/SPEC.md`
- `fvk/FINDINGS.md`
- `fvk/PROOF_OBLIGATIONS.md`
- `fvk/PROOF.md`
- `fvk/ITERATION_GUIDANCE.md`

Additional FVK adequacy/formal-core artifacts required by the FVK docs:

- `fvk/INTENT_SPEC.md`
- `fvk/PUBLIC_EVIDENCE_LEDGER.md`
- `fvk/FORMAL_SPEC_ENGLISH.md`
- `fvk/SPEC_AUDIT.md`
- `fvk/PUBLIC_COMPATIBILITY_AUDIT.md`
- `fvk/mini-django-bulk-update.k`
- `fvk/bulk-update-spec.k`

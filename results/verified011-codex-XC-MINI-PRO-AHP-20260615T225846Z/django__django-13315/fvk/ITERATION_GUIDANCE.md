# FVK Iteration Guidance

Status: constructed, not machine-checked. No tests, Python, or K tooling were
run.

## Code Decision

V1 stands unchanged. The FVK audit found the original bug mechanism and the
publicly rejected distinct-based alternative, then discharged the relevant proof
obligations against the V1 `Exists()` implementation.

No additional source edit is justified by the current public intent.

## Suggested Tests for a Normal Development Environment

Do not add tests in this benchmark task. In a normal Django development pass,
add or keep tests for:

1. A `ForeignKey` with `limit_choices_to=Q(...)` traversing a multi-valued join
   where two related rows match the same target object; rendered choices should
   include that target once.
2. Selecting that target in a `ModelChoiceField` should validate to the object
   rather than raising `MultipleObjectsReturned`.
3. A dictionary `limit_choices_to` should still work.
4. A callable returning a `Q` or dictionary should still be called for each form
   instantiation.
5. Empty `limit_choices_to` values such as `{}` and `Q()` should remain no-op.
6. A model with a custom non-comparable database field should not need
   row-wide `DISTINCT` for this fix.

## Future Verification Work

The current proof is a property-complete abstraction of the queryset
cardinality issue. A stronger FVK pass would require a real or richer Django ORM
SQL semantics covering:

- join construction for arbitrary `Q` trees,
- `OuterRef` resolution,
- `Exists` compilation across supported database backends,
- manager/base-manager interaction,
- database alias handling and router behavior.

Those are outside the bundled FVK fast path and should be treated as an
escalation boundary, not as a source bug in V1.

## Questions for Intent Elicitation

No blocking clarification is needed for this issue. If a broader behavior change
were considered, ask: should `ModelChoiceField` proactively deduplicate any
arbitrary user-supplied queryset, or only avoid duplicates introduced by
`limit_choices_to`? The public issue supports only the latter.

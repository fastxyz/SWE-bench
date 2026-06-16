# FVK Iteration Guidance

Status: constructed for audit, not machine-checked.

## Decision

V1 stands unchanged.

The FVK audit found that V1 satisfies the intent-derived proof obligations:

- PO-NORMAL-DISTINCT: normal join reuse is strong and keeps distinct
  `FilteredRelation` aliases separate.
- PO-FILTERED-PATH-REUSE: ON-clause condition resolution retains weak reuse for
  the current filtered path.
- PO-REUSE-SET-SCOPE: weak reuse is path-limited and cannot globally collapse
  unrelated filtered aliases.
- PO-CALLSITE-COMPATIBILITY: the defaulted internal parameters do not change
  existing source callsites.

## No V2 Code Edits

No additional source edit is recommended. The main tempting alternative,
changing `Join.equals()` globally, remains rejected because it would violate
PO-FILTERED-PATH-REUSE. Forcing every filtered relation to create a new alias
also remains rejected because it would violate the path-reuse behavior required
while compiling the filtered relation's own ON condition.

## Recommended Tests

Do not modify tests in this task. If tests were allowed, the public hint's
regression test should be added or kept:

- annotate two aliases on the same relation path,
- give them different `Q()` conditions,
- reference both aliases in `values()` or annotations,
- assert alias-specific results.

Existing integration tests should remain because the constructed proof is local
and not machine-checked.

## Commands For Future Machine Check

Do not run these in this benchmark session. In an environment with K installed,
the local proof artifacts would be checked with:

```sh
kompile fvk/mini-django-query.k --backend haskell
kast --backend haskell fvk/query-join-spec.k
kprove fvk/query-join-spec.k
```

## Next Human Review Focus

Review the proof boundary rather than the source algorithm:

- Is the abstraction from full SQL generation to alias-map cardinality adequate
  for this issue?
- Does `FilteredRelation.__eq__()` comparing alias and condition match the
  intended granularity of independent filtered aliases?
- Should Django intentionally reuse two different annotation names with exactly
  the same filtered relation identity, or is alias-level independence preferable?

The current public issue only requires independence for different filters, and
V1 preserves the stronger existing identity behavior where alias is part of the
filtered relation identity.


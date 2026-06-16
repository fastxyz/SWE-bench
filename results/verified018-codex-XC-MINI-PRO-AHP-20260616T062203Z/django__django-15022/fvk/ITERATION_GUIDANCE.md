# Iteration Guidance

Status: constructed, not machine-checked.

## Code decision

V1's core change is confirmed by O3, O4, and O5: collect per-token OR clauses
and submit them in one queryset filter call. V2 keeps that behavior and replaces
`filter(models.Q(*term_queries))` with `filter(*term_queries)` to remove an
unnecessary nested AND wrapper (F-002).

## Recommended tests for a future executable environment

Do not edit tests in this task. If tests can be added later, add focused
coverage for:

- Multi-word admin search over local fields still returns objects matching every
  word across at least one search field.
- Quoted phrases remain one token.
- Related-field multi-word admin search produces a query with one related join
  chain rather than one chain per token.
- `may_have_duplicates` remains true for duplicate-spawning lookup paths.
- Whitespace-only search input does not apply a search filter.

## Commands to run later, not in this workspace

```sh
kompile fvk/mini-admin-search.k --backend haskell
kast --backend haskell fvk/admin-search-spec.k
kprove fvk/admin-search-spec.k
```

Project tests or SQL-inspection tests should be run only in an environment where
running Django code is allowed.

## Open questions

No blocking open question remains. The only semantic ambiguity is F-003: whether
legacy chained filters across multi-valued relations should allow different
related rows to satisfy different tokens. The public docs and issue favor the
single-predicate behavior, so V2 should stand unless a maintainer explicitly
requires the legacy behavior.

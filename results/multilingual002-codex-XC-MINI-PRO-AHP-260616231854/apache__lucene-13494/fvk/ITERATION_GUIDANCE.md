# Iteration Guidance

Status: V1 stands unchanged.

## Decision

No source edits are required after the FVK audit.

The V1 change directly discharges the null-storage obligations in
`PROOF_OBLIGATIONS.md`:

- PO-002 proves the reported `getTopChildren` no-hit path.
- PO-003 covers the same state for `getAllChildren`.
- PO-005 and PO-006 cover `getSpecificValue`.
- PO-007 confirms dense and sparse non-empty paths stay unchanged.
- PO-009 confirms no public compatibility issue.

## If Continuing Development

Recommended tests to add in the normal project test suite, outside this benchmark
session:

- Reproducer using `MultiCollectorManager`, `FacetsCollectorManager`,
  `TopScoreDocCollectorManager`, and `MatchNoDocsQuery` for a low-cardinality
  field.
- A high-cardinality no-hit variant to cover the constructor branch that explicitly
  leaves both stores null.
- Accessor coverage for `getAllChildren` and `getSpecificValue` on the same
  empty-storage state.

Do not remove existing tests unless the emitted K commands are run and return
`#Top`.

## Future Proof Improvements

- Replace the abstract mini semantics with a richer Java/Lucene model if the audit
  target expands to label ordering, queue behavior, or doc-values iteration.
- Add termination and performance obligations only if requested; V1 adds constant
  guards before existing loops.
- Keep the compatibility audit focused on public signatures and overrides. The V1
  private helpers do not require caller migration.

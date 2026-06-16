# FVK Notes

## Decision

V1 stands unchanged. The FVK audit did not surface a source defect requiring a
V2 edit.

## Trace From Findings To Decisions

- `fvk/FINDINGS.md` F-001 identifies the original bug: normal query
  construction reused weak-equal joins and collapsed two distinct filtered
  aliases. `fvk/PROOF_OBLIGATIONS.md` PO-NORMAL-DISTINCT requires strong
  equality in normal join reuse. V1 satisfies this by using `j == join` in the
  normal `Query.join()` branch, so no additional edit is needed.
- F-002 identifies the preservation requirement that a filtered relation's own
  ON-clause condition must still reuse the filtered path alias. PO-FILTERED-
  PATH-REUSE and PO-REUSE-SET-SCOPE require weak equality only when compiling
  that condition and only for aliases in `set(filtered_relation.path)`. V1
  satisfies this by threading `reuse_with_filtered_relation=True` from
  `build_filtered_relation_q()` through `build_filter()`, `setup_joins()`, and
  `join()`.
- F-003 records that no public compatibility blocker was found. PO-CALLSITE-
  COMPATIBILITY requires existing callers to keep default behavior. The new
  parameters are defaulted and source callsites do not pass into the new
  positional slots, so no compatibility edit is needed.
- F-004 records the proof boundary: the constructed proof is local to alias
  reuse and not machine-checked. This justifies keeping tests and not claiming
  machine verification; it does not justify changing the source.

## Alternatives Rechecked

- Changing `Join.equals()` globally remains rejected because it would violate
  PO-FILTERED-PATH-REUSE by making ON-clause condition lookup unable to bind to
  the filtered join being compiled.
- Forcing every filtered relation to create a new alias remains rejected because
  it would bypass PO-FILTERED-PATH-REUSE and could introduce extra joins during
  condition compilation.
- Expanding the source change beyond `query.py` remains rejected because
  PO-SQL-OBSERVABLE is already discharged by the existing `Join.as_sql()` path
  once distinct aliases exist in `alias_map`.

## Execution Constraints

No tests, Python, or K tooling were run. The K commands are recorded in
`fvk/PROOF_OBLIGATIONS.md`, `fvk/PROOF.md`, and `fvk/ITERATION_GUIDANCE.md` for
future machine-checking in an environment that supports them.


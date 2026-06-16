# FVK Notes

## Decision summary

The FVK audit confirms the V1 source fix should stand unchanged. No additional production-code
edits were made in this phase.

The decisive obligations are PO-001 through PO-005 in `fvk/PROOF_OBLIGATIONS.md`. They cover the
full public failure: a fresh `IntervalBuilder.NO_INTERVALS` iterator must report `docID() == -1`,
must transition to `NO_MORE_DOCS` after `nextDoc()` or `advance(int)`, and must therefore be safe to
combine with other unpositioned iterators in `ConjunctionDISI.createConjunction`.

## Source-code decision

`repo/lucene/queries/src/java/org/apache/lucene/queries/intervals/IntervalBuilder.java`

Decision: keep V1 unchanged.

Trace:

- F-001 identifies the pre-fix state bug: `NO_INTERVALS.docID()` reported `NO_MORE_DOCS` before the
  iterator was positioned.
- PO-001 is discharged by V1's `private int doc = -1` field and `docID()` returning that field.
- PO-002 and PO-003 are discharged by V1 assigning `doc = NO_MORE_DOCS` in `nextDoc()` and
  `advance(int)`.
- PO-004 is discharged because `docID()` reads the same field after either exhaustion transition.
- F-002 and PO-005 connect those local state transitions to the reported conjunction failure:
  `ConjunctionDISI.createConjunction` requires all child iterators to start on the same doc id, and
  V1 makes the empty child agree with normal unpositioned siblings at `-1`.

No V2 refactor was justified. Replacing `NO_INTERVALS` with a null-returning no-match source would
change observable behavior outside the proof obligations. Adding broader interval-position state
changes to `start()` or `end()` was also rejected because F-003 and PO-006 frame the issue as a
`DocIdSetIterator` document-state bug; the conjunction failure reads `docID()`, not interval
position methods.

## FVK artifact changes

Added the required FVK markdown artifacts:

- `fvk/SPEC.md`
- `fvk/FINDINGS.md`
- `fvk/PROOF_OBLIGATIONS.md`
- `fvk/PROOF.md`
- `fvk/ITERATION_GUIDANCE.md`

Added two constructed formal-core files because the FVK instructions require K artifacts, even
though the benchmark forbids running K tooling:

- `fvk/mini-lucene-iterator.k`
- `fvk/no-intervals-spec.k`

These artifacts are tied to F-001 through F-004 and PO-001 through PO-006. They are explicitly
labeled constructed, not machine-checked.

## Verification constraints

No tests, project code, Python, `kompile`, or `kprove` were run. F-004 records this as an environment
and proof-tooling limitation, not as a code bug. Because the proof was not machine-checked, no test
removal is recommended.

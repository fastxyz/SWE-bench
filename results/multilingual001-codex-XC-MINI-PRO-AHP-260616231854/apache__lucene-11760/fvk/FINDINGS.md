# FVK Findings

Status: constructed, not machine-checked. Findings are derived from public intent and source
inspection only.

## F-001: Pre-fix empty iterator reports exhausted while unpositioned

Classification: code bug, resolved by V1.

Input/state: `IntervalBuilder.NO_INTERVALS.intervals(field, ctx)` immediately after construction,
before `nextDoc()` or `advance(int)`.

Observed before V1: `docID()` was hard-coded to `NO_MORE_DOCS`.

Expected: `docID()` returns `-1` while unpositioned, per the issue statement and
`DocIdSetIterator.docID()` contract.

V1 result by inspection: the anonymous iterator initializes `private int doc = -1`, and `docID()`
returns `doc`. This discharges PO-001.

## F-002: Pre-fix conjunction setup can reject a stopword-only interval query

Classification: code bug, resolved by V1.

Input/state: a conjunction containing one normal unpositioned interval iterator and one
`NO_INTERVALS` iterator produced by analyzed text with zero tokens, such as stopword-only text.

Observed before V1: the normal child reports `-1`, while `NO_INTERVALS` reports `NO_MORE_DOCS`.
`ConjunctionDISI.createConjunction` requires all children to have the same current doc id and throws
when they differ.

Expected: conjunction setup should see both children as unpositioned at `-1`; subsequent
`nextDoc()`/`advance(int)` should simply exhaust the conjunction because the empty child has no docs.

V1 result by inspection: `NO_INTERVALS.docID()` is initially `-1`, matching normal unpositioned
sibling iterators. This discharges PO-005.

## F-003: No additional source change justified for interval-position methods

Classification: audited non-change.

Input/state considered: `start()`, `end()`, `gaps()`, `nextInterval()`, `cost()`, `matchCost()`, and
`matches(...)` on the same empty iterator.

Observed in V1: these methods retain V0 behavior. In particular, the iterator still has no matching
documents or intervals, and `nextInterval()` returns `NO_MORE_INTERVALS`.

Expected for this issue: the public failure is the `DocIdSetIterator` document-state contract and
the conjunction setup check that reads `docID()`. Changing interval-position state is not needed to
remove the reported failure and would broaden the patch beyond the intent evidence.

Decision: keep V1's non-document methods unchanged. This is tied to PO-006.

## F-004: Proof/tooling not executed

Classification: proof capability / environment limitation, not a code bug.

Input/state: the constructed K files and claims under `fvk/`.

Observed: the benchmark forbids running `kompile`, `kprove`, tests, Python, or project code.

Expected: proof remains "constructed, not machine-checked" until the emitted K commands are run in a
proper environment.

Decision: no source change. Keep tests; do not remove or relax tests based on this unexecuted proof.

requires "mini-lucene-iterator.k"

module NO-INTERVALS-SPEC
  imports MINI-LUCENE-ITERATOR

  // SPEC-PROVENANCE:
  // - from_prompt: "DocIdSetIterators should return -1 when they are unpositioned" =>
  //   initial docID() of IntervalBuilder.NO_INTERVALS must be -1.
  // - from_docs: DocIdSetIterator.docID() returns -1 before nextDoc()/advance().
  // - from_code: V1 initializes the anonymous iterator field `doc` to -1.
  claim
    <k> docID => -1 ... </k>
    <doc> -1 </doc>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_docs: DocIdSetIterator.nextDoc() returns NO_MORE_DOCS when exhausted.
  // - from_prompt: NO_INTERVALS is an empty interval query, so it has no matching doc.
  // - from_code: V1 assigns `doc = NO_MORE_DOCS` in nextDoc().
  claim
    <k> nextDoc => NO_MORE_DOCS ... </k>
    <doc> -1 => NO_MORE_DOCS </doc>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_docs: DocIdSetIterator.advance(target) returns NO_MORE_DOCS when no doc can match.
  // - from_prompt: NO_INTERVALS is empty for all target docs.
  // - from_code: V1 assigns `doc = NO_MORE_DOCS` in advance(int).
  claim
    <k> advance(TARGET:Int) => NO_MORE_DOCS ... </k>
    <doc> -1 => NO_MORE_DOCS </doc>
    requires TARGET >=Int 0
    [all-path]

  // SPEC-PROVENANCE:
  // - from_docs: after exhaustion, docID() returns NO_MORE_DOCS.
  // - from_code: V1 stores NO_MORE_DOCS in the `doc` field after nextDoc()/advance().
  claim
    <k> docID => NO_MORE_DOCS ... </k>
    <doc> NO_MORE_DOCS </doc>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_code: ConjunctionDISI.createConjunction requires every child iterator to have
  //   the same current doc id.
  // - from_prompt: the bug appears when an empty interval query is combined in a conjunction.
  // - from_docs: unpositioned DocIdSetIterators report -1, so a normal unpositioned sibling
  //   and V1 NO_INTERVALS agree on -1 during conjunction setup.
  claim
    <k> sameDoc(-1, -1) => true ... </k>
    [all-path]

  // Diagnostic pre-fix contrast: V0's NO_MORE_DOCS-vs--1 initial pair is not a valid
  // conjunction setup state. This is evidence for FINDINGS.md, not a desired behavior.
  claim
    <k> sameDoc(NO_MORE_DOCS, -1) => false ... </k>
    [all-path]
endmodule

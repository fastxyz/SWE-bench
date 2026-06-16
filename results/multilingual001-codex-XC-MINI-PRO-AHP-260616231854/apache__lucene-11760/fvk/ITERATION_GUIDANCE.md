# Iteration Guidance

Status: V1 stands. No additional source edits are justified by the FVK audit.

## Decision

Keep the V1 source change in
`repo/lucene/queries/src/java/org/apache/lucene/queries/intervals/IntervalBuilder.java` unchanged.

The proof obligations focus on the document-position state of the empty interval iterator. V1
discharges those obligations with a minimal local state field and preserves the no-match behavior of
the sentinel source.

## If Iterating Further

1. Machine-check the constructed proof in an environment with K:

   ```sh
   kompile fvk/mini-lucene-iterator.k --backend haskell
   kast --backend haskell fvk/no-intervals-spec.k
   kprove fvk/no-intervals-spec.k
   ```

2. Add or keep tests that cover the public bug:

   - fresh `NO_INTERVALS` iterator: `docID() == -1`;
   - after `nextDoc()` or `advance(0)`: return and stored `docID()` are `NO_MORE_DOCS`;
   - stopword-only analyzed interval source inside a conjunction does not throw from initial
     doc-id mismatch.

3. Keep unrelated interval-position behavior out of this patch unless a separate public requirement
   asks for it. F-003 records why `start()`, `end()`, and interval matching methods were framed
   unchanged.

## No Test Removal Recommendation

Because the proof was not machine-checked and the benchmark forbids running the test suite, no tests
should be deleted or weakened.

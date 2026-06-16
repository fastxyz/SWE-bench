# FVK Notes

V1 stands unchanged.

## Decisions

1. I kept the one-line source fix in
   `repo/lucene/analysis/opennlp/src/java/org/apache/lucene/analysis/opennlp/OpenNLPSentenceBreakIterator.java`.

   Reason: `fvk/FINDINGS.md` F-001 identifies the pre-fix bug as the upper-middle
   midpoint for the length-two case. `fvk/PROOF_OBLIGATIONS.md` PO-001 and PO-002 show
   that V1 reproduces the failing mechanism for the old expression and removes it with
   `(sentenceStarts.length - 1) / 2`.

2. I did not add a guard inside `moveToSentenceAt`.

   Reason: F-002 and PO-003/PO-004 show that the helper is safe when callers preserve
   the non-base invariant `currentSentence < maxSentence`. V1 establishes that invariant
   at the `preceding` callsite, and the helper's recursive updates preserve it.

3. I did not alter public API, signatures, or return-offset behavior.

   Reason: F-003 and PO-005 show the fix is an internal expression change only.
   F-004 records that concrete return offsets were intentionally outside this
   exception-safety proof, and V1 does not change that behavior.

4. I did not run tests or formal tooling.

   Reason: the task forbids tests, Python, and K tooling. `fvk/PROOF.md` records the
   `kompile`, `kast`, and `kprove` commands that should be run later; all proof results
   are labeled constructed, not machine-checked.


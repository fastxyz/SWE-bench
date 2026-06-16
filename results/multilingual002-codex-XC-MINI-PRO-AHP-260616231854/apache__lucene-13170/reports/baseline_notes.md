# Baseline Notes

## Root cause

`OpenNLPSentenceBreakIterator.preceding(int pos)` initializes the binary search with
`sentenceStarts.length / 2`. For an even number of sentence starts, and especially when
there are exactly two sentences, this can choose the upper middle index. With two
sentences the initial `currentSentence` becomes `1`, while `moveToSentenceAt` is called
with the inclusive range `0..1`. If `pos` is in or after the second sentence,
`moveToSentenceAt` evaluates `sentenceStarts[currentSentence + 1]`, which becomes
`sentenceStarts[2]` and throws `ArrayIndexOutOfBoundsException`.

The matching `following(int pos)` method already starts from
`(sentenceStarts.length - 1) / 2`, which chooses the lower middle index. That keeps
`currentSentence + 1` valid while the search range still contains more than one entry.

## Changed files

- `repo/lucene/analysis/opennlp/src/java/org/apache/lucene/analysis/opennlp/OpenNLPSentenceBreakIterator.java`
  - Changed the initial `currentSentence` value in `preceding(int pos)` from
    `sentenceStarts.length / 2` to `(sentenceStarts.length - 1) / 2`.
  - This preserves the existing search algorithm and public behavior while preventing
    the out-of-bounds probe in `moveToSentenceAt`.

## Assumptions and alternatives considered

- I assumed the issue is specifically the unsafe initial binary-search index described
  in the local problem statement, not a broader request to change the iterator's
  documented `preceding` semantics.
- I considered changing `moveToSentenceAt` to guard `currentSentence + 1`, but rejected
  that because the caller can satisfy the method's implicit invariant with a smaller,
  more targeted change.
- I considered altering the `preceding` search range or return logic, but rejected that
  because existing local tests document the current behavior and the reported failure is
  an exception caused by the initial midpoint calculation.

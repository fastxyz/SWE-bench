# Intent Specification

Status: constructed from public/local evidence only. No hidden tests, internet, or
upstream patch knowledge were used.

## Scope

This FVK pass audits the V1 change for `OpenNLPSentenceBreakIterator.preceding(int pos)`
and its private recursive helper `moveToSentenceAt(int pos, int minSentence,
int maxSentence)`. The verified observable is the issue-reported failure class:
`ArrayIndexOutOfBoundsException` caused by probing `sentenceStarts[currentSentence + 1]`
during the binary search.

## Intent-Derived Obligations

I-001: Calling `preceding(int pos)` on an in-bounds offset must not raise
`ArrayIndexOutOfBoundsException` from `moveToSentenceAt`.

Evidence: `benchmark/PROBLEM.md` says `preceding` "may raise an
ArrayIndexOutOfBoundsException" and identifies that as the issue.

I-002: The "start search from the middle" computation in `preceding` should use the
lower-middle expression `(sentenceStarts.length - 1) / 2`.

Evidence: `benchmark/PROBLEM.md` states that `sentenceStarts.length / 2` "seems wrong"
and says it "should be instead" `(sentenceStarts.length -1) / 2`, like `following`.

I-003: The two-sentence case is in scope.

Evidence: `benchmark/PROBLEM.md` states that when `sentenceStarts.length == 2`,
`currentSentence` becomes `1` and can trigger the later out-of-bounds access.

I-004: The public API shape and existing non-exception behavior should be preserved
unless required to fix I-001.

Evidence: the issue requests a midpoint correction, not a signature or return-semantics
change. Public local tests exercise existing `preceding` return values; they do not
conflict with the reported exception-safety intent.

## Default-Domain Assumptions

D-001: Java array indices are valid exactly in `[0, length - 1]`.

D-002: Java integer division for non-negative values truncates toward zero. The midpoint
expressions in this proof operate over non-negative sentence counts and ranges.

D-003: This proof is partial correctness. It proves absence of the issue's
out-of-bounds access on the modeled search paths if the recursive search returns; it does
not separately prove recursion depth or performance.


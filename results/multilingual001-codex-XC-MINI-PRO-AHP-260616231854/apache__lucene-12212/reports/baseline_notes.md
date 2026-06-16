# Baseline Notes

## Root cause

`DrillSidewaysScorer.score` positioned the base scorer with `baseIterator.nextDoc()` before choosing a scoring strategy. For scorers with a `TwoPhaseIterator`, that full iterator confirms the first candidate by calling `TwoPhaseIterator.matches()`. The query-first paths then used `baseApproximation` and called `baseTwoPhase.matches()` for the same document again, violating the `TwoPhaseIterator` contract that `matches()` is called at most once per iterator position. Phrase-based scorers are sensitive to this because `matches()` advances phrase-position state.

The same eager full-iterator positioning also made it unsafe to simply switch the first advance to the approximation unless the chunked scoring paths confirmed base candidates themselves. Otherwise those paths could treat an approximation-only base document as a confirmed base match.

## Files changed

`repo/lucene/facet/src/java/org/apache/lucene/facet/DrillSidewaysScorer.java`

- Changed initial base scorer positioning from `baseIterator.nextDoc()` to `baseApproximation.nextDoc()`, so two-phase base queries are only moved to their first candidate and are not confirmed before the selected scoring branch handles them.
- Updated `doDrillDownAdvanceScoring` to advance `baseApproximation` and explicitly check `baseTwoPhase.matches()` before scoring or counting a base document.
- Updated `doUnionScoring` to iterate `baseApproximation` and explicitly check `baseTwoPhase.matches()` before accepting a base document.

`reports/baseline_notes.md`

- Added this required implementation note covering the root cause, source change, assumptions, and rejected alternative.

## Assumptions and alternatives considered

I assumed the intended invariant is that `DrillSidewaysScorer` should call a base scorer's two-phase matcher exactly once per candidate document, matching the way drill-down dimensions already use their approximations plus two-phase checks.

I considered the one-line replacement suggested in the issue text. That fixes the query-first double-match case, but by itself it leaves `doUnionScoring` and `doDrillDownAdvanceScoring` reading from `baseIterator` after only the approximation was positioned. Since Lucene's two-phase iterator wrapper reports the approximation's `docID()`, those branches could see an unconfirmed candidate as the current base doc. I rejected that narrower change and updated the two chunked branches to confirm base candidates explicitly.

I did not change tests because the task forbids modifying test files, and I did not run tests or project code because the task states this session has no execution environment.

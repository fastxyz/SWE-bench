# Baseline Notes

## Root cause

`IntervalBuilder.NO_INTERVALS` returns an `IntervalIterator` for analyzed text that produces no
tokens, such as text reduced entirely to stopwords. That iterator's `docID()` method always returned
`NO_MORE_DOCS`, even before the iterator had been positioned with `nextDoc()` or `advance()`.

This violates the `DocIdSetIterator` contract: `docID()` must return `-1` while unpositioned and
`NO_MORE_DOCS` only after the iterator has been exhausted. When this empty interval iterator is used
inside conjunction logic, callers can observe it as already exhausted during setup instead of as an
unpositioned iterator, which can trigger incorrect control flow and exceptions.

## Files changed

`repo/lucene/queries/src/java/org/apache/lucene/queries/intervals/IntervalBuilder.java`

Added a private `doc` state field to the anonymous `IntervalIterator` returned by
`NO_INTERVALS.intervals(...)`. The field starts at `-1`, `docID()` returns that field, and both
`nextDoc()` and `advance(int)` set it to `NO_MORE_DOCS` before returning. This mirrors the state
behavior of Lucene's empty `DocIdSetIterator` while preserving the existing no-interval behavior for
positions, cost, and matching.

`reports/baseline_notes.md`

Added this report documenting the diagnosis, source edit, assumptions, and alternatives considered.

## Assumptions

The intended behavior is that the sentinel interval iterator should remain non-null but obey the
same document-position state contract as other `DocIdSetIterator` implementations. I assumed callers
may rely on receiving an `IntervalIterator` from `NO_INTERVALS.intervals(...)`, so the fix should not
change that method to return `null`.

I also assumed the issue is limited to document iterator state. The existing `start()` and `end()`
methods continue to return `NO_MORE_INTERVALS`, because the iterator never matches any document or
interval and the reported failure concerns `docID()` before positioning.

## Alternatives considered and rejected

One alternative was replacing `NO_INTERVALS` with the existing `NoMatchIntervalsSource`, whose
`intervals(...)` method returns `null`. I rejected that because it would change the observable
behavior of `IntervalBuilder.NO_INTERVALS` more broadly than necessary and could affect callers that
currently expect a non-null empty iterator.

Another alternative was wrapping `DocIdSetIterator.empty()` and delegating only document iteration
state to it. I rejected that because the anonymous `IntervalIterator` already implements the full
empty interval behavior locally, and adding a separate delegate would be a larger change than a
single local state field.

## Verification

No tests or project code were run, in accordance with the benchmark instructions. Verification was
limited to read-only inspection of the issue statement, relevant source files, and the resulting
diff.

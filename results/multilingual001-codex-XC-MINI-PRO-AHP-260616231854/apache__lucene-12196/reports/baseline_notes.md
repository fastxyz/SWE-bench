# Baseline Notes

## Root cause

`MultiFieldQueryParser` applies field boosts by wrapping each per-field query in `BoostQuery`.
For quoted terms with explicit slop, its `applySlop` helper only recognized `PhraseQuery` and
`MultiPhraseQuery`. Once the phrase was wrapped, the helper could not see the underlying phrase
query, so the parsed slop was dropped while the boost was preserved.

## Files changed

`repo/lucene/queryparser/src/java/org/apache/lucene/queryparser/classic/MultiFieldQueryParser.java`

- Updated `applySlop` to recognize `BoostQuery`, apply the existing slop logic to the wrapped
  query, and rewrap the result with the original boost value. This keeps the existing phrase and
  multi-phrase rebuilding behavior while preserving boosts.

`reports/baseline_notes.md`

- Added this report describing the root cause, the changed file, assumptions, and rejected
  alternatives.

## Assumptions and alternatives considered

I assumed the intended behavior is for explicit phrase slop to apply to the underlying phrase query
regardless of whether `MultiFieldQueryParser` configured a per-field boost.

I considered moving boost application after `applySlop` in the multi-field path. That would fix the
reported example, but it would leave `applySlop` unable to handle already-boosted query wrappers and
would make the method more fragile. Handling `BoostQuery` inside `applySlop` is more targeted to the
actual failure mode and preserves the existing call order.

I did not modify tests because the task explicitly forbids changing test files, and I did not run the
test suite or project code because the task states that no execution environment is available.

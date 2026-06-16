# Formal Spec English

Status: constructed, not machine-checked.

## Claim `PRE_FIX_COUNTEREXAMPLE`

For a two-element `sentenceStarts` array, the pre-fix `preceding` midpoint expression
`N / 2` sets `currentSentence` to `1`. In a non-base search frame with range `0..1`, the
helper may evaluate `currentSentence + 1`, which is `2`, outside the valid array range.
The modeled outcome is `arrayIndexOutOfBounds`.

## Claim `PRECEDING_V1_SAFE`

For any positive sentence-start length `N`, V1 `preceding` initializes
`currentSentence` to `(N - 1) / 2` before searching the inclusive range `0..N-1`. If
`N == 1`, the helper is immediately in a base frame and does not evaluate
`currentSentence + 1`. If `N > 1`, the initial current index is strictly below
`maxSentence`, so `currentSentence + 1` is within range before the helper can read it.

## Claim `MOVE_SAFE`

For any helper frame with `0 <= minSentence <= currentSentence <= maxSentence < N` and
with the additional non-base invariant `minSentence < maxSentence` implies
`currentSentence < maxSentence`, all modeled recursive branches preserve safety:

- the already-at-target branch performs no next-index read;
- the left branch moves to `minSentence..currentSentence-1` and chooses a lower midpoint
  inside that smaller range;
- the right branch moves to `currentSentence+1..maxSentence` and either reaches a base
  frame or chooses an index strictly below `maxSentence`.

Therefore every non-base frame that may inspect `sentenceStarts[currentSentence + 1]`
has `currentSentence + 1 <= maxSentence < N`.

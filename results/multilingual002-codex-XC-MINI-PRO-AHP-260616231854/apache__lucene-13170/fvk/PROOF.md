# Constructed Proof

Status: constructed, not machine-checked. No `kompile`, `kast`, `kprove`, tests, Python,
or project code were executed.

## Machine-Check Commands Not Executed

```sh
kompile fvk/mini-java-break-iterator.k --backend haskell
kast --backend haskell fvk/opennlp-sentence-break-iterator-spec.k
kprove fvk/opennlp-sentence-break-iterator-spec.k
```

Expected machine-check result after installing/running K: `kprove` discharges the claims
to `#Top`. Until then, this remains a constructed proof only.

## Theorem

For every `preceding` call that reaches the modeled search branch with
`sentenceStarts.length = N > 0`, V1 cannot throw the issue-reported
`ArrayIndexOutOfBoundsException` from the helper's read of
`sentenceStarts[currentSentence + 1]`.

## Pre-Fix Counterexample

For `N = 2`, the pre-fix code computes:

```text
currentSentence = N / 2 = 2 / 2 = 1
minSentence = 0
maxSentence = N - 1 = 1
```

The helper frame is non-base because `minSentence != maxSentence`. The right-branch test
may read `sentenceStarts[currentSentence + 1]`, which is `sentenceStarts[2]`. Valid
indices for length two are `0` and `1`, so the modeled outcome is
`arrayIndexOutOfBounds`.

This discharges PO-001 and corresponds to K claim `PRE_FIX_COUNTEREXAMPLE`.

## V1 Initial Frame

V1 computes:

```text
currentSentence = (N - 1) / 2
minSentence = 0
maxSentence = N - 1
```

Case `N == 1`: `currentSentence = 0` and `minSentence == maxSentence == 0`. The helper is
in its base case, so the non-base read that produced the issue is unreachable.

Case `N > 1`: because Java integer division truncates non-negative values toward zero,
`(N - 1) / 2 <= N - 2`. Therefore:

```text
currentSentence < maxSentence
currentSentence + 1 <= maxSentence < N
```

The first helper frame can safely evaluate the non-base right-branch test. This
discharges PO-002 and corresponds to K claim `PRECEDING_V1_SAFE`.

## Helper Invariant

Invariant:

```text
0 <= minSentence <= currentSentence <= maxSentence < N
minSentence < maxSentence implies currentSentence < maxSentence
```

When `minSentence == maxSentence`, the helper is in its base frame. The failing non-base
read is not performed.

When `minSentence < maxSentence`, the invariant gives:

```text
currentSentence + 1 <= maxSentence < N
```

So `sentenceStarts[currentSentence + 1]` is in bounds.

## Branch Preservation

Left branch:

The branch can move left only when `currentSentence > minSentence`. The new max is
`currentSentence - 1`, and the new current is:

```text
minSentence + (currentSentence - minSentence) / 2
```

That value is at least `minSentence` and at most `currentSentence - 1`. If the new range
is non-base, it is strictly below the new max; otherwise the recursive frame is base.

Right branch:

The branch can move right only when `currentSentence < maxSentence`. The new min is
`currentSentence + 1`, and the new current is:

```text
maxSentence - (maxSentence - currentSentence) / 2
```

If `maxSentence - currentSentence == 1`, then the new min equals `maxSentence`, so the
recursive frame is base. If the difference is at least two, the division term is at least
one, so the new current is at most `maxSentence - 1`, preserving the non-base invariant.

This discharges PO-003 and PO-004 and corresponds to K claim `MOVE_SAFE`.

## Compatibility

The source-level diff changes only:

```java
currentSentence = (sentenceStarts.length - 1) / 2;
```

inside `preceding(int pos)`. There is no API or caller-protocol change. This discharges
PO-005.

## Test Recommendations

No tests were modified. Because this proof is constructed but not machine-checked, no
test should be removed on its basis.

When test edits are allowed in a normal development setting, add or keep a regression
test for two detected sentences where `preceding` is called with an offset in or after
the second sentence. Existing integration and tokenizer tests should remain because this
proof abstracts OpenNLP detection, `CharacterIterator`, and concrete returned offsets.

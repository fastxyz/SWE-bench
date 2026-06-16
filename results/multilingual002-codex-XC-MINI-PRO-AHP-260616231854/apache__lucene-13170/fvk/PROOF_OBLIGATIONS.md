# Proof Obligations

Status: constructed, not machine-checked.

## PO-001: Reproduce the pre-fix failure mechanism

Show that with `N = sentenceStarts.length = 2`, the old midpoint `N / 2` gives
`currentSentence = 1`, and a non-base helper frame over `0..1` can attempt to read index
`currentSentence + 1 = 2`.

Expected result: modeled `arrayIndexOutOfBounds`.

Evidence: E-001, E-003.

K claim: `PRE_FIX_COUNTEREXAMPLE`.

## PO-002: V1 initial midpoint is safe for the initial helper frame

Show that after V1 initializes `currentSentence = (N - 1) / 2`:

- if `N == 1`, the helper starts with `minSentence == maxSentence == 0`, so the non-base
  read is unreachable;
- if `N > 1`, `0 <= currentSentence < N - 1 == maxSentence`, so
  `currentSentence + 1 <= maxSentence < N`.

Evidence: E-002, E-003.

K claim: `PRECEDING_V1_SAFE`.

## PO-003: Helper invariant makes every non-base read valid

For every helper frame, prove:

`0 <= minSentence <= currentSentence <= maxSentence < N` and
`minSentence < maxSentence -> currentSentence < maxSentence`.

Then the helper's non-base read of `sentenceStarts[currentSentence + 1]` is valid because
`currentSentence + 1 <= maxSentence < N`.

Evidence: E-001.

K claim: `MOVE_SAFE`.

## PO-004: Recursive branches preserve the helper invariant

Left branch:

- Preconditions imply `minSentence < currentSentence`.
- New range is `minSentence..currentSentence-1`.
- New current is `minSentence + (currentSentence - minSentence) / 2`, which lies inside
  the new range and is strictly below the new max for every non-base recursive frame.

Right branch:

- Preconditions imply `currentSentence < maxSentence`.
- New range is `currentSentence+1..maxSentence`.
- New current is `maxSentence - (maxSentence - currentSentence) / 2`.
- If `maxSentence - currentSentence == 1`, the recursive frame is a base frame.
- Otherwise the new current is strictly below `maxSentence`.

Evidence: source helper code and E-001.

K claim: `MOVE_SAFE`.

## PO-005: Compatibility frame

Show that the repair does not alter public API or caller protocol.

Evidence: E-005 and local source search for constructor/call sites.

Audit: `PUBLIC_COMPATIBILITY_AUDIT.md`.

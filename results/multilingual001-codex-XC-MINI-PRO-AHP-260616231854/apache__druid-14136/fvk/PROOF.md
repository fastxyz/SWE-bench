# Constructed Proof

Status: constructed, not machine-checked. No tests, Python, `kompile`, or `kprove` were run.

## What Is Proved

For every selected holder list satisfying the selection invariant in `fvk/SPEC.md`, the V1 clipping phase in `VersionedIntervalTimeline.lookup` returns holder intervals bounded by the requested query interval, preserves holder payload fields, and maps the reported zero-length interior query case from `[T,T]` and selected `[HS,HE]` with `HS < T < HE` to `[T,T]`.

## Proof Sketch

1. Empty list: production returns `retVal` immediately; K claim C-EMPTY rewrites `lookupClip(QS,QE,.List)` to `.List`.
2. First holder start: V1 branches on `QS > firstStart`. If true, it constructs `[QS, firstEnd]`; selected invariant gives `QS < firstEnd`, so the interval is valid. If false, the original first start is already at or after the query start.
3. Last holder end: V1 branches on `QE < lastEnd`. If true, it constructs `[lastStart, QE]`. For distinct first and last holders, the selected invariant gives `lastStart < QE`. For a single selected holder whose start was already clipped by the first-holder step, `lastStart = QS`, and the query-domain fact `QS <= QE` makes `[QS,QE]` valid, including `[T,T]` for the zero-length issue case. If false, the original last end is already at or before the query end.
4. Middle holders: the production code only calls `retVal.set` for index `0` and the last index, so all middle holders are framed unchanged.
5. Payload frame: each replacement holder is constructed with the prior holder's true interval, version, and object.

## Reported Bug Derivation

Pre-fix symbolic path for one selected holder:

- Start with query `[T,T]` and selected holder `[HS,HE]`, where `HS < T < HE`.
- First clip sees `T > HS` and returns `[T,HE]`.
- Pre-fix last clip asks `query.overlaps([T,HE])`. Public issue evidence says this is false when the query is zero-length and has the same start instant as the holder.
- Therefore the end remains `HE`, producing a positive holder interval `[T,HE]`.

V1 symbolic path:

- Start with the same query and holder.
- First clip returns `[T,HE]`.
- Last clip checks only `T < HE`, which is true, and returns `[T,T]`.

This discharges F-001 and PO-005.

## Machine-Check Commands Not Run

The following commands are the constructed reproduction commands for a later environment with K installed:

```sh
cd fvk
kompile mini-java-interval-timeline.k --backend haskell
kast --backend haskell versioned-interval-timeline-spec.k
kprove versioned-interval-timeline-spec.k
```

Expected machine-check result after installing and running K tooling: `kprove` returns `#Top` for the stated claims. This expectation is constructed, not observed.

## Test Guidance

Do not remove any tests from this repository based on this pass. The proof is not machine-checked, and the task forbids modifying test files. A future test suite should include a public regression for a zero-length query strictly inside a selected holder interval and assert that the returned holder interval is zero length.

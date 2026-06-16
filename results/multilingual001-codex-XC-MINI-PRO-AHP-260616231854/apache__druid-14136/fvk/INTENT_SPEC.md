# Intent Specification

Status: constructed from public evidence, not machine-checked.

## Target

`VersionedIntervalTimeline.lookup(Interval)` and `lookupWithIncompletePartitions(Interval)` return `TimelineObjectHolder` entries for visible timeline intervals matching the requested query interval.

## Required Behavior

1. A query interval must not cause returned holder intervals to extend outside the requested query interval after lookup clipping.
2. A zero-length query interval, such as `T/T`, should match no data rows. If a timeline holder is selected because its original adjusted interval contains `T` in its interior, the returned holder interval must be clipped to `T/T`, not `T/originalEnd`.
3. The object payload, true interval, version, partition chunks, and list order of selected holders must be preserved by the clipping phase.
4. The public method signatures and returned holder shape must remain compatible with existing callsites that build `SegmentDescriptor(holder.getInterval(), holder.getVersion(), chunkNumber)`.
5. Other uses of `Interval.overlaps` should be changed only if they can expand a zero-length query into a non-zero interval or otherwise contradict the public issue intent.

## Domain Assumptions

- Intervals are half-open endpoint pairs `[start, end)` with `start <= end`; zero-length intervals are in-domain.
- Adjusted timeline intervals stored in `completePartitionsTimeline` and `incompletePartitionsTimeline` have positive duration. This is supported by `addIntervalToTimeline`, which only inserts intervals with `toDurationMillis() > 0`.
- The initial lookup scan selects holders using Joda's existing `timelineInterval.overlaps(queryInterval)` behavior. The fix is scoped to clipping selected holders and does not redefine Joda overlap.

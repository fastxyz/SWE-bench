# Baseline Notes

## Root Cause

`VersionedIntervalTimeline.lookup` selected timeline entries with `timelineInterval.overlaps(interval)`, then clipped the first and last selected holders back to the requested interval. The clipping checks repeated the overlap test in the opposite direction with `interval.overlaps(holderInterval)`.

For a zero-length lookup interval, Joda `Interval.overlaps` can return false from the zero-length interval side even when the timeline entry was selected by the earlier check. As a result, a selected holder was left with its original non-zero end time. A zero-length query could therefore be planned against a non-zero holder interval and scan data after the requested instant.

## Files Changed

- `repo/processing/src/main/java/org/apache/druid/timeline/VersionedIntervalTimeline.java`
  - Removed the redundant `interval.overlaps(...)` guards from the first and last holder clipping checks.
  - The lookup now clips selected holders using endpoint comparisons only. Since every holder in `retVal` was already selected by `timelineInterval.overlaps(interval)`, the endpoint comparisons are sufficient and also handle zero-length lookup intervals.
  - Added a short comment explaining why clipping must not be gated on the zero-length lookup interval's `overlaps` result.

## Assumptions And Alternatives

- I assumed the intended behavior is to preserve the existing lookup flow and return selected holders clipped to the requested interval, including a zero-length clipped holder when the selected timeline interval contains the lookup instant. This matches the issue description, which specifically identifies the missing end-time adjustment.
- I considered making `lookup` immediately return an empty list for zero-length intervals. I rejected that because it would be a broader semantic change to timeline lookup and the reported root cause is the clipping guard, not the initial timeline selection.
- I reviewed other `overlaps` uses in `VersionedIntervalTimeline`. The remaining ones are used for non-empty stored timeline keys during add/remove/overshadow logic or for the initial selection direction (`timelineInterval.overlaps(interval)`), so I left them unchanged.
- I also checked nearby production overlap usages outside the timeline. The similar query-side checks I found either reject work when a zero-length interval does not overlap data, or preserve the zero-length interval instead of expanding it, so they do not cause the described "matches too much data" behavior.

No tests were run, per the task instructions.

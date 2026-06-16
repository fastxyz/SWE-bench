# Public Evidence Ledger

Status: constructed from allowed public inputs only.

| ID | Source | Evidence | Semantic Obligation | Status |
|---|---|---|---|---|
| E-001 | `benchmark/PROBLEM.md` | "Zero-length interval matches too much data" | Zero-length query intervals are in-domain and must not expand to non-zero data scans. | Encoded in `SPEC.md`, `versioned-interval-timeline-spec.k`, PO-005. |
| E-002 | `benchmark/PROBLEM.md` | "should really match nothing" | The observable query result for `T/T` should contain no rows. At the timeline layer, selected holder intervals must be clipped to zero length so downstream scanning sees no positive interval. | Encoded in PO-005. |
| E-003 | `benchmark/PROBLEM.md` | "The problem is in `VersionedIntervalTimeline.lookup`" | The audited production unit is lookup's holder selection and clipping behavior. | Encoded in scope. |
| E-004 | `benchmark/PROBLEM.md` | "`interval1.overlaps(interval2)` does not consider the intervals to be overlapping if `interval1` is zero-length and has the same start instant as `interval2`" | Clipping must not rely on `queryInterval.overlaps(holderInterval)` after the holder has been selected. | Encoded in PO-003 and PO-004. |
| E-005 | `benchmark/PROBLEM.md` | "This causes the `interval.overlaps(lastEntry.getInterval())` check to be false, so the end instant of the timeline holder is not adjusted." | The last holder must be end-clipped by endpoint comparison when `queryEnd < holderEnd`, including after first-holder clipping has made starts equal. | Encoded in PO-004 and PO-005. |
| E-006 | `benchmark/PROBLEM.md` | "There may be other places that `overlaps` is used in a similar way, so we should check those too." | Audit other overlap checks for the same expanding-interval pattern. | Encoded in FINDING F-004. |
| E-007 | Source: `VersionedIntervalTimeline.lookup` | Selected holders are instantiated with `timelineInterval`, true interval, version, and copied visible chunks. | Clipping should frame true interval, version, object, selection order, and cardinality. | Encoded in PO-006. |
| E-008 | Source: `CachingClusteredClient` and `ServerManager` callsites | Callers build `SegmentDescriptor` from `holder.getInterval()`. | The returned holder interval is the consumer-visible query interval; clipping correctness affects data scanned. | Encoded in PO-007. |
| E-009 | Source: `addIntervalToTimeline` | Timeline maps only store intervals with positive duration. | Selected holder intervals have positive duration before lookup clipping; zero-length intervals arise only from query clipping. | Encoded as a domain assumption. |

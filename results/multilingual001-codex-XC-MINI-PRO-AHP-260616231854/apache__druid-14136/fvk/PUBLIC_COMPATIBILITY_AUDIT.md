# Public Compatibility Audit

Status: constructed, not machine-checked.

## Changed Symbols

- `VersionedIntervalTimeline.lookup(Interval)`
- `VersionedIntervalTimeline.lookupWithIncompletePartitions(Interval)`, through the shared private lookup implementation.

## Signature And Type Compatibility

- No method signature changed.
- No constructor signature changed.
- `TimelineObjectHolder` return shape is unchanged.
- The list element order and payload object references are preserved by the clipping phase.

## Public Consumers Checked

- `server/src/main/java/org/apache/druid/client/CachingClusteredClient.java`
  - Builds `SegmentDescriptor(holder.getInterval(), holder.getVersion(), chunkNumber)`.
  - V1 preserves this protocol and improves the interval bound passed to query runners.
- `server/src/main/java/org/apache/druid/server/coordination/ServerManager.java`
  - Builds `SegmentDescriptor` from lookup holders.
  - V1 preserves this protocol and improves the interval bound passed to query runners.
- `server/src/main/java/org/apache/druid/client/CachingQueryRunner.java`
  - Aligns a descriptor interval to the actual data interval without expanding a zero-length interval into a positive interval.
  - No compatibility change required.

## Result

No public API, virtual dispatch, constructor, or producer/consumer shape incompatibility was found.

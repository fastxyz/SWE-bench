# Baseline Notes

## Root Cause

`WorkerTaskCountStatsMonitor` selected its backing task-count provider with a binary role check: MiddleManager nodes used `WorkerTaskCountStatsProvider`, and every other node used `IndexerTaskCountStatsProvider`. In a MiddleManager plus Peon deployment, Peons are started with `NodeRole.PEON` and inherit the configured monitor list, but Peons do not bind `IndexerTaskCountStatsProvider`. The monitor constructor therefore tried to resolve an Indexer-only provider in the Peon injector and failed before the task could start.

## Files Changed

`repo/server/src/main/java/org/apache/druid/server/metrics/WorkerTaskCountStatsMonitor.java`

Added an explicit `NodeRole.INDEXER` check before resolving `IndexerTaskCountStatsProvider`. The monitor now resolves `WorkerTaskCountStatsProvider` only for MiddleManager nodes, resolves `IndexerTaskCountStatsProvider` only for Indexer nodes, and acts as a no-op for unsupported roles such as Peon. This keeps the MiddleManager and Indexer metric behavior intact while allowing Peons to start when the monitor class appears in their inherited monitor configuration.

## Assumptions and Alternatives

I assumed Peons should not emit worker task-count metrics because they do not bind either provider and the documented support for these worker metrics is tied to MiddleManager/Indexer-style worker services, not individual task Peons.

I considered adding a Peon binding for `IndexerTaskCountStatsProvider`, but rejected it because Peons do not own the Indexer-level task accounting required by that interface. I also considered filtering the monitor out in `MetricsModule`, but rejected that broader change because the bug is local to `WorkerTaskCountStatsMonitor` assuming every non-MiddleManager role is an Indexer.

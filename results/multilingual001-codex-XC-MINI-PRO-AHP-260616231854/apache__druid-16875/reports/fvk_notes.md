# FVK Notes

The FVK audit confirms V1 should stand unchanged.

The central decision is tied to F-001 and PO-001/PO-004: the reported Peon failure occurs because the pre-V1 constructor requested `IndexerTaskCountStatsProvider` for every non-MiddleManager role. The V1 source now has an explicit `NodeRole.INDEXER` branch and an unsupported-role branch that leaves both providers null, so Peon construction no longer performs the unbound lookup and `doMonitor` no-ops.

I kept the MiddleManager path unchanged because PO-002 requires preservation of the `WorkerTaskCountStatsProvider` lookup and existing MiddleManager metric family. I kept the Indexer path unchanged because PO-003 requires preservation of the public Indexer metrics, and F-003 records that Indexer support is public/tested even though one configuration doc line is narrower.

I did not add a Peon binding for `IndexerTaskCountStatsProvider` because F-001 localizes the bug to a role-selection error in the monitor, and PO-001 requires no Indexer lookup in Peon rather than a fake provider. I did not filter the monitor in `MetricsModule` because PO-004 is satisfied locally by making unsupported roles harmless. I did not modify tests because the task forbids test edits; F-002 records the recommended regression test for future work.

The K artifacts in `fvk/mini-java-monitor.k` and `fvk/worker-task-count-stats-monitor-spec.k` are constructed only and were not run. The commands to machine-check them are recorded in `fvk/PROOF.md` and `fvk/PROOF_OBLIGATIONS.md`.


# Iteration Guidance

Status: constructed, not machine-checked.

## Decision

V1 stands unchanged.

## Why No Source Change Is Needed

F-001 and PO-001 show that the reported `NoneType` subscript is resolved by guarding `cursor.fetchone()` before indexing it.

F-002 and PO-002 show that the deterministic `CULL_FREQUENCY = 1` no-row case is resolved by deleting all current rows directly.

F-003 and PO-003 show that normal culling with a present cutoff row is preserved.

PO-004 and PO-005 show that zero-frequency and below-limit behavior are unchanged.

## Open Follow-Up Outside This Issue

F-004 records that negative `CULL_FREQUENCY` is outside the documented domain. A separate hardening task could validate cache options, but this issue does not require it.

F-005 records that full database concurrency semantics are an escalation boundary for this mini model. Keep conventional database backend tests and do not remove tests based on this constructed proof.

## Next Verification Step

When a K environment is available, run:

```sh
kompile fvk/mini-cache-cull.k --backend haskell
kast --backend haskell fvk/database-cache-cull-spec.k
kprove fvk/database-cache-cull-spec.k
```

Do not treat test deletion as justified unless the machine check returns `#Top` and conventional database tests also pass.

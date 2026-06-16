# FVK Iteration Guidance

Status: V1 stands unchanged.

## Decision

Keep the V1 source patch in `repo/django/db/migrations/executor.py`.

Reason: FINDINGS F-001 identifies the pre-V1 bug and PO-003, PO-004, and PO-006
show that V1 closes it. FINDINGS F-002 and PO-001, PO-002, and PO-007 show that
V1 preserves the existing apply-side reconciliation behavior. FINDINGS F-005 and
PO-008 show no public compatibility regression.

## No Further Source Edit

No source edit is justified by the FVK audit.

The audit considered moving the delete into `unapply_migration()`, but PO-006
shows the current centralized reconciliation point already composes correctly
with `unapply_migration()`. Keeping the logic in `check_replacements()` also
keeps no-op reconciliation covered by PO-007.

The audit considered updating an in-memory `applied` snapshot inside the loop,
but no public intent evidence requires a fixed-point reconciliation over nested
replacement keys. The issue concerns the direct replacement target rows left
after unapplying a squashed migration. Changing snapshot semantics would be a
broader behavioral change than the proof obligations require.

## Later Machine Check

The proof is constructed, not machine-checked. In an environment with K
available, run:

```sh
kompile fvk/mini-migrations.k --backend haskell
kast --backend haskell fvk/migration-executor-spec.k
kprove fvk/migration-executor-spec.k
```

Expected result: `kprove` returns `#Top` for the abstract claims.

## Later Tests

Do not remove tests based on this audit. Future tests to add in a normal
development setting:

- a backward migration of a squashed migration removes the squashed migration
  row from `django_migrations`;
- the same recorder result holds for fake backward migration;
- applying all replaced migrations still records the squashed migration as
  applied.

## Residual Risk

The K files model recorder state as a set of migration keys, not as a full
database with timestamps or duplicate physical rows. FINDINGS F-003 explains why
that abstraction is adequate for the issue's observable.

The audit is partial correctness over the reconciliation state. It does not
prove database transaction behavior, schema operation behavior, migration graph
construction, performance, or termination of Django's broader migration system.

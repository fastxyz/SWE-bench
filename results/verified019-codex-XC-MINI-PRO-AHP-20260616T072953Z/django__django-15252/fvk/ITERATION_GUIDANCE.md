# Iteration Guidance

Status: constructed, not machine-checked.

## Decision for This Pass

V1 stands unchanged as V2.

Reason:
`F-1` and `F-2` are the concrete source bugs derived from public intent. They
are discharged by `PO-1` through `PO-7`. `F-5` confirms public callsite
compatibility through `PO-8`.

## Source Changes Not Made

No additional production-code edits were made during the FVK pass.

The main rejected change was an app-label-level guard in
`MigrationExecutor.record_migration()`. This was rejected because of `F-3` and
`PO-9`: the public issue itself notes that router decisions are model-level
while migration records are app-level. A generic app-level guard could skip
recording a migration that partially ran, which would introduce a different
history inconsistency.

## Future Work

1. If Django wants to solve the broader "record only migrations that actually
   did database work" problem, add or expose an operation-level execution
   signal. The migration executor could then record only when at least one
   operation actually ran, without guessing from app labels.
2. Add focused public tests for the resolved obligations:
   - disallowed recorder model: `ensure_schema()` doesn't create;
   - disallowed recorder model: `applied_migrations()` returns `{}` without
     `has_table()`;
   - disallowed recorder model: `record_applied()` and `record_unapplied()` do
     not create or write;
   - empty executor plan: `migrate()` does not create `django_migrations`;
   - allowed recorder model: legacy creation and writes still work.
3. Keep integration tests for multi-database test database creation. The FVK
   proof is unit-level and does not replace end-to-end coverage.
4. Keep tests for custom migration operations. The proof treats arbitrary custom
   operations as a proof boundary (`F-4`), not as verified behavior.

## Commands for Later Machine Checking

Do not run these in this benchmark session. They are recorded for a future
environment with K installed:

```sh
kompile fvk/mini-django-migrations.k --backend haskell
kast --backend haskell fvk/migration-recorder-spec.k
kprove fvk/migration-recorder-spec.k
```

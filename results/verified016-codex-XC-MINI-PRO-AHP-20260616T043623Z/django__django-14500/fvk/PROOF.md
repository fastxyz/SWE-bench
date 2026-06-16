# FVK Proof

Status: constructed, not machine-checked. No tests, Python, `kompile`, `kast`,
or `kprove` were run.

## Claims Proved by Construction

The proof targets the abstract recorder-state contract in `SPEC.md`.

For every replacement migration key `k` in `self.loader.replacements`, after
`check_replacements()`:

- `k` is present iff all keys in `migration.replaces` were present in the entry
  applied set.
- non-replacement keys are unchanged.

This proves the issue path because `unapply_migration()` removes the individual
replaced rows for a replacement migration, and `migrate()` then calls
`check_replacements()` unconditionally.

## Case Proof for `check_replacements()`

Fix a replacement key `k`, target set `R(k)`, and entry applied set `A`.

Case 1, `all_applied` is true and `k` is absent from `A`:
V1 executes `record_applied(*key)`. By `MigrationRecorder`'s row-presence
semantics, `k` is present in the post-state. This discharges PO-001.

Case 2, `all_applied` is true and `k` is already present in `A`:
V1 executes no delete branch. `k` remains present. This discharges PO-002.

Case 3, `all_applied` is false and `k` is present in `A`:
V1 executes `record_unapplied(*key)`. By `MigrationRecorder`'s row-deletion
semantics, `k` is absent in the post-state. This discharges PO-003.

Case 4, `all_applied` is false and `k` is already absent from `A`:
V1 executes no write. `k` remains absent. This discharges PO-004.

The loop over `self.loader.replacements.items()` applies this case split to
each replacement key. The only recorder writes use those replacement keys, so
non-replacement keys are framed unchanged. This discharges PO-005.

## Composition Proof

Unapply path:

1. For a replacement migration `k`, `unapply_migration()` calls
   `record_unapplied()` for every `(app_label, name)` in `migration.replaces`.
2. Therefore, after `unapply_migration()`, at least one target in `R(k)` is
   absent; in the ordinary squashed migration case all targets in `R(k)` are
   absent.
3. `migrate()` calls `check_replacements()` after the backward plan.
4. By PO-003 or PO-004, `k` is absent after reconciliation.

This discharges PO-006 and closes FINDINGS F-001.

Apply/no-op path:

1. If every target in `R(k)` is present, `all_applied` is true.
2. By PO-001 or PO-002, `k` is present after reconciliation.

This discharges PO-007 and preserves FINDINGS F-002.

Compatibility:

The V1 diff adds no new parameters, return values, storage formats, or public
dispatch obligations. This discharges PO-008.

Honesty:

No machine-check result or test result is claimed. This discharges PO-009.

## Machine-Check Commands for Later

These commands are emitted for a later environment. They were not run here.

```sh
kompile fvk/mini-migrations.k --backend haskell
kast --backend haskell fvk/migration-executor-spec.k
kprove fvk/migration-executor-spec.k
```

Expected later outcome after machine checking: `kprove` reduces the stated
claims to `#Top`. Until those commands are actually run, the result remains
constructed, not machine-checked.

## Test Recommendation

No tests were edited. Because the proof is not machine-checked, no tests should
be removed on the basis of this FVK pass.

Useful future tests, if editing tests is allowed in a normal development
setting:

- unapplying a squashed replacement migration removes the replacement row as
  well as all replaced rows;
- fake-unapplying the same path has the same recorder reconciliation result;
- a no-op migrate with all replaced rows present still records the replacement
  row as applied.

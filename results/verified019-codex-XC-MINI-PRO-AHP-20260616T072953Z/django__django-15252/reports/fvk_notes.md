# FVK Notes

## Decision Summary

V1 stands unchanged as V2. The FVK audit found no additional source edit that is
both required by the public intent and safe within Django's current migration
recording API.

## Decisions Traced to Findings and Proof Obligations

1. Kept `MigrationRecorder.migration_table_allowed()` unchanged.
   - Finding: `F-1` identifies the missing router check as the concrete bug.
   - Obligation: `PO-1` requires using Django's existing
     `router.allow_migrate_model(alias, Migration)` API.
   - Decision: V1 already implements exactly that helper.

2. Kept the router guard at the top of `ensure_schema()`.
   - Finding: `F-1` shows the pre-fix failure was unwanted
     `django_migrations` creation on a router-disallowed alias.
   - Obligations: `PO-2` requires no-op behavior when disallowed, and `PO-3`
     requires preserving allowed-database behavior.
   - Decision: V1 satisfies both by returning before `has_table()` and keeping
     the old create/error path after the guard.

3. Kept the short-circuit in `applied_migrations()`.
   - Finding: `F-1` covers recorder access on disallowed aliases.
   - Obligation: `PO-4` requires `{}` without checking or querying the
     disallowed recorder table.
   - Decision: V1's `self.migration_table_allowed() and self.has_table()`
     branch satisfies this through Python short-circuiting.

4. Kept the no-op guards in `record_applied()` and `record_unapplied()`.
   - Finding: `F-1` identifies indirect creation/write through
     `record_applied()`; `IE-4` extends the same issue to `record_unapplied()`.
   - Obligation: `PO-5` requires both write paths to return before schema or
     row writes when disallowed.
   - Decision: V1 satisfies the obligation with identical upfront guards.

5. Kept the guarded `flush()`.
   - Finding: `F-5` confirms compatibility; `IE-4` supports applying the same
     recorder write policy across recorder methods.
   - Obligation: `PO-6` requires no delete on disallowed aliases.
   - Decision: V1's `migration_table_allowed() and has_table()` check satisfies
     this without changing the method signature.

6. Kept the delayed executor `ensure_schema()` call.
   - Finding: `F-2` identifies eager recorder table creation for empty plans.
   - Obligation: `PO-7` requires no eager schema setup when `plan` is empty.
   - Decision: V1 computes or receives `plan` first and calls
     `ensure_schema()` only under `if plan:`.

7. Did not add an app-label-only guard to `record_migration()`.
   - Finding: `F-3` records the ambiguity between model-level router decisions
     and app-level migration records.
   - Obligation: `PO-9` rejects a generic app-label-only recording guard
     without an operation-level "actually ran" signal.
   - Decision: No V2 code edit was made for this broader interpretation.

8. Did not change public method signatures.
   - Finding: `F-5` confirms compatibility.
   - Obligation: `PO-8` requires preserving public API shape.
   - Decision: V1 remains source-compatible for existing callers.

## Verification Caveat

The proof package is constructed, not machine-checked. Per the task
constraints, I did not run tests, Python, `kompile`, `kast`, or `kprove`.

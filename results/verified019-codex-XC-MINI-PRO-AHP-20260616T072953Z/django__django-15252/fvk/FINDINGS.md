# FVK Findings

Status: constructed, not machine-checked. These findings come from public
intent and static source inspection only.

## F-1: Resolved Code Bug - Recorder Table Creation Ignored Routers

Evidence: `IE-1`, `IE-2`, `IE-3`.

Concrete input:

- Connection alias: `other`.
- Router decision: `router.allow_migrate_model("other", MigrationRecorder.Migration) == False`.
- Pre-state: `django_migrations` absent.
- Operation: `MigrationRecorder(connection).record_applied("app", "0001_initial")`.

Pre-fix observed behavior:
`record_applied()` called `ensure_schema()`, and `ensure_schema()` attempted to
create `django_migrations` before inserting a row.

Expected behavior:
No recorder table creation and no recorder row write on the disallowed alias.

V1/V2 status:
Resolved by `PO-2` and `PO-5`. The current code checks
`migration_table_allowed()` before creating or writing.

## F-2: Resolved Code Bug - Empty Plans Forced Recorder Table Creation

Evidence: `IE-5`.

Concrete input:

- Migration plan: empty.
- Pre-state: `django_migrations` absent.
- Operation: `MigrationExecutor.migrate(targets, plan=[])`.

Pre-fix observed behavior:
`migrate()` called `self.recorder.ensure_schema()` before inspecting the plan,
so an empty plan could still create `django_migrations`.

Expected behavior:
No eager recorder table creation when no migration records can be written.

V1/V2 status:
Resolved by `PO-7`. The current code computes or receives `plan` first and
calls `ensure_schema()` only when `plan` is truthy.

## F-3: Ambiguous Broader Interpretation - App-Level Records vs Model-Level Routing

Evidence: `IE-8`.

Concrete scenario:

- A migration contains multiple model operations in one app.
- A router allows one model in that app on the target database and disallows
  another model in the same app.
- Django's migration history table records `(app_label, migration_name)`, not
  individual operation or model outcomes.

Potential expected behavior:
Some issue comments ask Django not to record migrations whose operations did
not run.

Reason this did not justify a V2 source change:
The public discussion also identifies the mismatch: `allow_migrate()` is
model-level while migration history is app-level. Without an operation-level
"this database operation actually ran" signal, an app-label-only recording
guard can either skip records for migrations that partially did run or record
migrations that partially did not run. That is a design/API question rather
than a safe minimal source edit for this issue.

V1/V2 status:
Not a blocker for the scoped fix. Captured as `PO-9` and as future iteration
guidance.

## F-4: Proof Capability Boundary - Custom Migration Operations

Evidence: implementation inspection of the migration operation protocol.

Concrete scenario:

- Router disallows the recorder model.
- A third-party custom migration `Operation` ignores routers and mutates the
  database directly.

Observed from source shape:
The recorder proof can show no recorder table effects on a disallowed alias,
but it cannot prove arbitrary custom operations respect routers.

Expected behavior:
The issue's concrete failure is recorder table creation/writes, not arbitrary
third-party operation behavior.

V1/V2 status:
Proof boundary, not a source bug in the touched code. Future verification would
need operation-level contracts for custom operations.

## F-5: Compatibility Finding - Public Signatures Preserved

Evidence: public callsite scan and `IE-7`.

Concrete input:
Existing calls to `ensure_schema()`, `applied_migrations()`,
`record_applied(app, name)`, `record_unapplied(app, name)`, `flush()`, and
`migrate(targets, plan=..., state=..., fake=..., fake_initial=...)`.

Observed current behavior:
The V1 patch adds no required parameters and changes no return shape used by
callers.

Expected behavior:
Existing public callsites remain source-compatible.

V1/V2 status:
Confirmed by `PO-8`. No compatibility source edit is required.

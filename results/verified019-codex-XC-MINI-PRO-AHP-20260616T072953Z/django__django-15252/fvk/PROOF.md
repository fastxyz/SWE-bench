# Constructed Proof

Status: constructed, not machine-checked. No `kompile`, `kast`, `kprove`,
Python, or Django tests were run.

## Machine-Check Commands Not Run

The commands that would machine-check the FVK core are:

```sh
kompile fvk/mini-django-migrations.k --backend haskell
kast --backend haskell fvk/migration-recorder-spec.k
kprove fvk/migration-recorder-spec.k
```

Expected result after a successful machine check: all claims discharge to
`#Top`.

## Trusted Base

This proof relies on:

- adequacy of the small K abstraction in `fvk/mini-django-migrations.k`;
- the public intent ledger in `fvk/SPEC.md`;
- source inspection of `repo/django/db/migrations/recorder.py` and
  `repo/django/db/migrations/executor.py`;
- the K reachability proof system if the commands above are later run.

The proof is partial correctness over the audited side effects. Termination is
not separately proved because the modeled methods contain only straight-line
branches in the audited slice.

## Proof Sketch by Obligation

### PO-1: Router Decision

Source:

```python
def migration_table_allowed(self):
    return router.allow_migrate_model(self.connection.alias, self.Migration)
```

The helper is definitionally equal to the established router query. By
`ConnectionRouter.allow_migrate_model()`, the call supplies the app label,
model name, and model object for `MigrationRecorder.Migration`. This discharges
`PO-1`.

### PO-2 and C-1: Disallowed `ensure_schema()`

Source:

```python
if not self.migration_table_allowed():
    return
```

Symbolic state:

- `allowed = false`
- arbitrary `hasTable = H`
- arbitrary `creates = C`

K step:

```k
<k> ensureSchema => .K </k>
<allowed> false </allowed>
```

No rule changes `hasTable` or `creates`. Therefore the post-state preserves
`H` and `C`, proving no table creation when routers disallow the recorder
model.

### PO-3 and C-2: Allowed `ensure_schema()` Creation Path

Symbolic state:

- `allowed = true`
- `hasTable = false`
- arbitrary `creates = C`

K step:

```k
<k> ensureSchema => .K </k>
<allowed> true </allowed>
<hasTable> false => true </hasTable>
<creates> C => C +Int 1 </creates>
```

This mirrors the unchanged source path: after the new router guard passes,
`has_table()` is checked; if false, `schema_editor().create_model()` is called.
The existing `DatabaseError` wrapping remains unchanged in source and is outside
the no-error K path. This preserves the legacy allowed-database behavior.

### PO-4 and C-3: Disallowed `applied_migrations()`

Source:

```python
if self.migration_table_allowed() and self.has_table():
    ...
else:
    return {}
```

When `migration_table_allowed()` is false, Python's `and` short-circuits, so
`has_table()` and `migration_qs` are not evaluated. The method returns `{}`.

K step:

```k
<k> appliedMigrations => .K </k>
<allowed> false </allowed>
<reads> R => R </reads>
<result> _ => 0 </result>
```

The abstract `result = 0` denotes the empty migration mapping.

### PO-5, C-4, and C-5: Disallowed Record Writes

Both write methods now start with:

```python
if not self.migration_table_allowed():
    return
```

For `record_applied()`, the K claim preserves `hasTable`, `creates`, and
`writes` when `allowed = false`. For `record_unapplied()`, it preserves
`hasTable`, `creates`, and `deletes` when `allowed = false`.

Because the return happens before `ensure_schema()`, neither method can create
the recorder table as an indirect side effect on a disallowed alias.

### PO-6 and C-6: Disallowed `flush()`

Source:

```python
if self.migration_table_allowed() and self.has_table():
    self.migration_qs.all().delete()
```

When `migration_table_allowed()` is false, the `and` short-circuits. The delete
query is not reached. The K claim preserves `deletes` for `flushRecorder` with
`allowed = false`.

### PO-7, C-7, and C-8: Executor Eager Schema Setup

Source:

```python
if plan is None:
    plan = self.migration_plan(targets)
if plan:
    self.recorder.ensure_schema()
```

Case split:

1. `planNonEmpty = false`: `executorMigrate` rewrites to `.K` without invoking
   `ensureSchema`. `hasTable` and `creates` are unchanged. This proves empty
   plans do not create the recorder table only for bookkeeping.
2. `planNonEmpty = true`: `executorMigrate` invokes `ensureSchema`. If
   `allowed = false`, the proof reduces to `C-1`, so no table creation occurs.
   If `allowed = true`, the proof reduces to the legacy `ensureSchema` paths.

This discharges `PO-7` while preserving the early schema check for non-empty
plans.

### PO-8: Compatibility

The proof obligation is syntactic and callsite-based:

- no existing public method gains a required argument;
- no existing method changes its documented return shape;
- `ensure_schema()` still returns normally with no consumed return value;
- `applied_migrations()` still returns a mapping.

The static callsite scan found callers invoking the same signatures. The source
diff confirms no signature changes. `PO-8` is discharged.

### PO-9: Rejected Broader App-Level Recording Guard

The public issue contains a broader concern about recording migrations whose
operations did not actually run. The proof does not encode an app-label-only
recording guard because `IE-8` shows the design mismatch: routers decide at
model granularity, while migration records are app/migration rows.

An app-label-only proof obligation would be under-specified and could fail a
mixed-model migration where some operations legitimately run. Therefore the
constructed proof treats this as iteration guidance, not a source requirement
for V2.

## Test Guidance

No tests were run or modified. If the K proof is machine-checked later, unit
tests that only assert `PO-2` through `PO-7` point cases may be considered
redundant, but removal would still be recommendation-only and conditioned on
`kprove` returning `#Top`.

Tests to keep or add:

- router-disallowed `record_applied()` does not create `django_migrations`;
- router-disallowed `applied_migrations()` returns `{}` without checking table
  existence;
- router-disallowed `record_unapplied()` and `flush()` do not write;
- `MigrationExecutor.migrate(plan=[])` does not create `django_migrations`;
- allowed/default database behavior still creates and records normally;
- mixed-model routing remains a design test for any future operation-level
  recording change.

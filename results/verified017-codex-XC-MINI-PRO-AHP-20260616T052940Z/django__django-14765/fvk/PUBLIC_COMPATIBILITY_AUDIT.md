# PUBLIC COMPATIBILITY AUDIT

Status: constructed from allowed source inspection; no runtime checks were run.

## Changed Symbol

- Symbol: `django.db.migrations.state.ProjectState.__init__`.
- Signature change: none.
- Behavioral change: non-`None` non-set `real_apps` values now assert instead
  of being converted to a set.

## Source Call Sites

- `repo/django/db/migrations/graph.py:309`: `ProjectState()` omits
  `real_apps`; compatible with `PO1`.
- `repo/django/db/migrations/graph.py:313`: `ProjectState(real_apps=real_apps)`
  forwards the `make_state()` parameter.
- `repo/django/db/migrations/loader.py:338`: `make_state()` is called with
  `real_apps=self.unmigrated_apps`.
- `repo/django/db/migrations/loader.py:71`: `self.unmigrated_apps` is
  initialized as `set()`.
- `repo/django/db/migrations/executor.py:69`: passes
  `self.loader.unmigrated_apps`, the same set-valued producer.
- `repo/django/db/migrations/state.py:413`: clone passes `self.real_apps`,
  which is set-valued after successful construction.

## Public Documentation Surface

`repo/docs/ref/migration-operations.txt` describes `ProjectState` as a
semi-internal migration framework object passed to operations, with `apps` as
the relevant usage point. It does not document `real_apps` constructor input as
accepting arbitrary iterable values.

## Compatibility Finding

External code that directly called `ProjectState(real_apps=<iterable non-set>)`
will now raise `AssertionError` under normal assertion semantics. This is the
behavior requested by the issue, and is recorded as `F4`.


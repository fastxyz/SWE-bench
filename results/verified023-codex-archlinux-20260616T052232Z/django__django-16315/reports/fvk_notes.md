# FVK Notes

## Decisions

F-001 and proof obligations O1-O3 confirm the original V1 direction: the
upsert path must not pass raw model field names to backend conflict SQL
generation. The source fix remains centered on resolving `update_fields` and
`unique_fields` to `Field` objects and then compiling their `column` values.

F-002 and O4 identified a V1 compatibility risk: V1 resolved option names even
when `on_conflict` was not `OnConflict.UPDATE`. V2 changes
`repo/django/db/models/query.py` so the added `opts.get_field()` conversions are
guarded by `on_conflict == OnConflict.UPDATE`.

F-003 and O5 identified a V1 backend-boundary risk: V1 sent generator
expressions into `on_conflict_suffix_sql()`. V2 changes
`repo/django/db/models/sql/compiler.py` to materialize column-name lists on the
update-conflict path, preserving the hook's list-like identifier input shape.

O6 confirms that the existing `"pk"` alias handling in `unique_fields` remains
unchanged. The alias is still normalized before validation and before the new
guarded field resolution, so `unique_fields=["pk"]` continues to compile from
the primary key field's database column.

## Verification Boundary

F-004 records that no remaining source bug was found in the audited path after
V2. F-005 records the honesty boundary: no tests, Python, or K commands were run
because the task forbids execution. The FVK artifacts include the commands and
expected proof shape, but the proof remains constructed, not machine-checked.

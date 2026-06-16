# Proof Obligations

Status: constructed, not machine-checked.

## Obligations

O1. `alter_unique_together()` passes `primary_key=False` when deleting old
`unique_together` entries.

- Evidence: source line in `repo/django/db/backends/base/schema.py`.
- Discharges: F-002 primary-key duplicate case.
- Status: satisfied by V2.

O2. `_constraint_names()` candidate filtering still applies columns,
`unique=True`, `primary_key=False`, and explicit exclusions before
disambiguation.

- Evidence: unchanged `_constraint_names()` call and existing helper logic.
- Discharges: excludes primary key and explicit Meta constraints/indexes.
- Status: satisfied by V2.

O3. If multiple unique candidates remain and the generated `_uniq` name is
present, the generated name becomes the sole deletion target.

- Evidence: V2 computes `_create_index_name(..., suffix="_uniq")`, normalizes it
  with `identifier_converter()`, and filters to that name when present.
- K claims: K-UT-DEFAULT-FIRST, K-UT-DEFAULT-SECOND.
- Status: constructed proof.

O4. Candidate order does not matter when the generated name is present.

- Evidence: membership test `if default_name in constraint_names`.
- K claims: K-UT-DEFAULT-FIRST, K-UT-DEFAULT-SECOND.
- Status: constructed proof.

O5. If no generated-name candidate exists among multiple unique candidates, the
existing `ValueError` behavior remains.

- Evidence: V2 only rewrites `constraint_names` when `default_name in
  constraint_names`; otherwise the later length check raises.
- K claim: K-UT-AMBIGUOUS.
- Status: constructed proof.

O6. If exactly one candidate remains after filtering, the existing delete path
remains.

- Evidence: V2 generated-name branch only runs for `len(constraint_names) > 1`.
- K claim: K-UT-SINGLE.
- Status: constructed proof.

O7. The `_uniq` preference is not applied to `index_together` deletion or other
non-unique composed-index deletion.

- Evidence: branch is guarded by `constraint_kwargs.get("unique") is True`.
- K claim: K-NONUNIQUE-AMBIGUOUS.
- Status: constructed proof.

O8. The `_delete_composed_index()` signature remains baseline-compatible.

- Evidence: V2 signature is `_delete_composed_index(self, model, fields,
  constraint_kwargs, sql)`.
- Discharges: F-001.
- Status: satisfied by V2 source inspection.

O9. Creation-path behavior for adding redundant single-field `unique_together`
is not proven.

- Evidence: `alter_unique_together()` still executes `_create_unique_sql()` for
  new entries.
- Finding: F-003.
- Status: open follow-up ambiguity, not blocking the deletion fix.

O10. Manual rename behavior is not guaranteed when ambiguity remains.

- Evidence: generated-name selection intentionally relies on Django's default
  `_uniq` naming scheme.
- Finding: F-004.
- Status: residual risk accepted by public hint.

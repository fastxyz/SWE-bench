# FVK Findings

Status: constructed, not machine-checked. Findings are derived from public intent, source inspection, and proof obligations; no tests or code were run.

## F1 - Resolved by V1: FK metadata lost target collation

Input scenario: a `ForeignKey` or `OneToOneField` references a text-like primary key with `db_collation="utf8_bin"`.

Observed in pre-V1 source: `ForeignKey.db_parameters()` returned only `{"type": ..., "check": ...}`. The schema editor's column creation path could not see the target collation through `field.db_parameters()`.

Expected from E1-E3: FK column definitions should carry the target collation.

V1 status: resolved by `repo/django/db/models/fields/related.py`, where `ForeignKey.db_parameters()` now includes `target_field.db_parameters(...).get("collation")`.

Proof obligations: PO1, PO2.

## F2 - Resolved by V1: Alter path ignored collation-only referenced-target changes

Input scenario: a primary key or unique target field changes from no explicit collation to `db_collation="utf8_bin"`, or changes/removes an existing explicit collation, while retaining the same database type.

Observed in pre-V1 source: `drop_foreign_keys` was guarded only by `old_type != new_type`, so collation-only changes did not drop/rebuild incoming FK constraints or update related FK columns.

Expected from E2-E4: changing/adding/removing target collation must be reflected on FK fields and constraints.

V1 status: resolved by `repo/django/db/backends/base/schema.py`, where `drop_foreign_keys` now considers `old_collation != new_collation`.

Proof obligations: PO3.

## F3 - Resolved by V1: Related FK alter SQL needed target collation while preserving nullability

Input scenario: changing `Account.id` from `BigAutoField` to a collated `varchar(22)` primary key with both non-null and nullable incoming FKs.

Observed in pre-V1 source: the related-column loop passed only `rel_db_params["type"]` to `_alter_column_type_sql()`, producing MySQL statements such as `MODIFY account_id varchar(22) NOT NULL` without collation.

Expected from E1-E2: related FK alter SQL includes the target collation. Expected from E5: existing backend type-alter handling, including MySQL nullability, is preserved.

V1 status: resolved by appending `self._collate_sql(rel_collation)` to `rel_type` before calling the backend type-alter helper.

Proof obligations: PO4.

## F4 - Confirmed frame condition: Target check constraints are not propagated

Input scenario: FK target field has database check metadata in its own `db_parameters()`.

Observed in V1 source: `ForeignKey.db_parameters()` reads target parameters only to copy `collation`; it keeps `check` as `self.db_check(connection)`.

Expected from C5: the fix should solve collation matching without copying unrelated target constraints onto FK columns.

V1 status: confirmed.

Proof obligations: PO1, PO5.

## F5 - Confirmed compatibility: Additive `db_parameters()` key is consumed defensively

Input scenario: existing callers read `field.db_parameters(connection)`.

Observed source audit: schema code already uses `.get("collation")` where collation matters, and test/source searches did not find exact-dictionary equality assumptions over FK `db_parameters()`. Existing direct consumers read named keys such as `"type"` and `"check"`.

Expected from C5: no public signature change or incompatible producer/consumer shape.

V1 status: confirmed. The return dict has an additional optional key, matching the existing `CharField` and `TextField` pattern.

Proof obligations: PO5.

## F6 - Proof capability caveat, not a code defect

The K model is an issue-specific abstraction and was not machine-checked. It proves semantic propagation of collation through the relevant schema-editor transitions, not exact backend SQL grammar, migration autodetector behavior, or live MySQL acceptance.

Recommended handling: keep integration/backend tests for SQL text and database execution. Do not remove tests unless the emitted K commands are run and return `#Top`, and even then keep backend integration tests outside the abstract model's scope.

# FVK Specification

Status: constructed, not machine-checked. No tests, Python, `kompile`, or `kprove` were run.

## Scope

This FVK pass audits the V1 production-code changes for `django__django-15629`:

- `repo/django/db/models/fields/related.py::ForeignKey.db_parameters()`
- `repo/django/db/backends/base/schema.py::BaseDatabaseSchemaEditor._alter_field()`
- Existing column SQL consumers in `BaseDatabaseSchemaEditor.column_sql()` and `_iter_column_sql()`
- Existing backend type-alter behavior relevant to MySQL nullability, especially `repo/django/db/backends/mysql/schema.py::_alter_column_type_sql()`

## Intent Specification

The intended behavior is not "whatever V1 emits"; it is derived from the public issue text and hints.

1. A `ForeignKey` or `OneToOneField` whose target field has an explicit `db_collation` must produce a database column definition with the same collation.
2. When a referenced primary key or unique target field changes type and/or `db_collation`, referencing FK columns must be altered to the matching database type and collation before FK constraints are recreated.
3. A collation-only target change, including adding or removing `db_collation`, is schema-significant for related FK columns and constraints.
4. Existing backend-specific related-column type behavior must be preserved, including MySQL's use of `NULL`/`NOT NULL` in `MODIFY` statements.
5. The fix should not propagate unrelated target-field database parameters, such as check constraints, onto FK columns.

## Public Evidence Ledger

| ID | Source | Evidence | Semantic obligation | Status |
| --- | --- | --- | --- | --- |
| E1 | `benchmark/PROBLEM.md` | "COLLATE should also be present in the ... account_id ... modification statements." | FK column alter SQL must include target collation. | Encoded by PO1, PO3, PO4. |
| E2 | `benchmark/PROBLEM.md` | "The collation of the pk must match the collation of the fk otherwise an error will occur." | FK database parameters must mirror target collation. | Encoded by PO1 and PO2. |
| E3 | Public hint | "add it to the db_params so that changes to the target db_collation will be reflected on the FK field and its constraints." | `ForeignKey.db_parameters()` must expose target collation; alter logic must use `db_parameters()`. | Encoded by PO1, PO3. |
| E4 | Public hint | "changing/adding/removing a db_collation." | Collation-only changes are in scope, not only type changes. | Encoded by PO3. |
| E5 | Existing source | `_iter_column_sql()` emits `field_db_params.get("collation")`; MySQL `_alter_column_type_sql()` preserves old-field nullability. | Reuse existing schema-editor surfaces instead of adding unrelated APIs. | Encoded by PO2, PO4. |

## Formal Model

The abstract K model in `fvk/mini-django-schema.k` represents only the property under verification:

- `Params(type, check, collation)` abstracts `Field.db_parameters()`.
- `Field(type, null, primary_key, unique, db_constraint, params)` abstracts the field facts used by the schema editor.
- `fkParams(field)` abstracts `ForeignKey.db_parameters()`.
- `createColumnSql(field)` abstracts column creation/addition SQL generation.
- `dropIncomingFks(old, new)` abstracts the `_alter_field()` decision to drop/rebuild incoming FK constraints.
- `relatedAlterSql(field)` abstracts related FK column alteration.

This model intentionally omits unrelated Django behavior: migrations autodetection, constraint-name generation, SQL quoting details, index creation, defaults, and database execution. Those are frame conditions outside the issue-specific observable.

## Contracts

### C1: FK Parameter Propagation

For any FK whose target field parameters contain collation `C`, `ForeignKey.db_parameters(connection)["collation"] == C`, while `["type"]` remains the existing `ForeignKey.db_type()` result and `["check"]` remains `ForeignKey.db_check()`.

### C2: Create/Add Column Collation

For any FK field with `db_parameters()["collation"] == C`, `column_sql()` and `add_field()` pass that collation to `_iter_column_sql()`, which emits a collated column definition when `C` is truthy.

### C3: Referenced Target Alter Trigger

For an old/new referenced primary key or unique field pair, incoming FK constraints and related columns must be processed when either the database type changes or the database collation changes.

### C4: Related Column Alter Output

For each related FK field selected by C3, the related-column type passed to the backend type-alter helper must include the new target collation when present. Existing backend nullability handling must remain in force.

### C5: Frame Conditions

The fix must not:

- alter test files;
- change `ForeignKey.db_type()` or target `rel_db_type()` semantics;
- copy target check constraints onto FK columns;
- change FK constraint naming or ordering outside the already-existing drop/alter/recreate sequence;
- introduce a new public method signature.

## Adequacy Audit

The formal claims in `fvk/django-15629-spec.k` paraphrase to C1-C4 and directly cover E1-E4. C5 is a frame condition checked by source inspection and public-callsite search, not by the K fragment.

The proof is adequate for the reported issue because the observable failure is an FK `ADD CONSTRAINT` after FK column SQL omitted target collation. The modeled contributors include both sources of that observable: the FK field metadata used by column SQL, and the referenced-target alter path that updates related columns before constraints are rebuilt.

Residual limitation: the model abstracts SQL text order and quoting. The intent requires semantic presence of the matching collation, not an exact textual ordering such as `NOT NULL COLLATE` versus `COLLATE ... NOT NULL`.

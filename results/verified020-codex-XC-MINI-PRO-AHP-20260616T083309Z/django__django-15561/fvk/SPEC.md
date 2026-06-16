# FVK Spec: SQLite choices-only AlterField

Status: constructed, not machine-checked. No tests, Python, or K tooling were
run.

## Target

The audited unit is the field-alteration decision used by schema editors:

* `BaseDatabaseSchemaEditor._field_should_be_altered(old_field, new_field)`
* `DatabaseSchemaEditor.alter_field()` in the SQLite backend, which returns
  early when `_field_should_be_altered()` is false.

The observable being specified is whether an `AlterField` operation proceeds to
schema-changing SQL. On SQLite, proceeding for most field changes means remaking
the table.

## Intent Ledger

| ID | Source | Evidence | Semantic obligation | Status |
| --- | --- | --- | --- | --- |
| I1 | `benchmark/PROBLEM.md` | "AlterField operation should be noop when adding/changing choices on SQLite." | If the old and new fields differ only in `choices`, SQLite must classify the field as not requiring alteration. | Encoded by PO5 and claim `SQLITE-CHOICES-NOOP`. |
| I2 | `benchmark/PROBLEM.md` | "even a seemingly db-transparent change like adding choices still generates sql (new table + insert + drop + rename)" | The pre-fix SQLite path is a bug because it reaches the table-remake path for metadata-only `choices` changes. | Finding F1. |
| I3 | `benchmark/PROBLEM.md` | "would cause a regression for third-party enum fields" and "safely overwrite `_field_should_be_altered()` only on SQLite." | Do not make `choices` globally non-database-affecting. Other backends must keep the base decision behavior. | Encoded by PO4 and claim `BASE-CHOICES-STILL-ALTERS`. |
| I4 | Source code | The base editor already strips `blank`, `db_column`, `editable`, `error_messages`, `help_text`, `limit_choices_to`, `on_delete`, `related_name`, `related_query_name`, `validators`, and `verbose_name`. | Preserve the previous base ignored-attribute set exactly, then extend it only for SQLite. | Encoded by PO2 and PO3. |
| I5 | FVK compatibility rule | Changed symbols and virtual/subclass hooks must be audited. | Avoid introducing a public-looking extension point unless needed. | Finding F2; V2 uses a private method-specific class attribute. |

## Domain

The contract ranges over Django field objects for which:

* `deconstruct()` returns `(name, path, args, kwargs)`;
* `column` can be compared after the schema editor's `quote_name()` handling;
* `choices` is represented in `kwargs` when it differs from the field default;
* for Django's core SQLite backend, `choices` is validation/form metadata and
  does not change the database column definition by itself.

This spec is partial correctness: it specifies the alteration decision if the
method returns. It does not prove termination, database execution, or SQL parser
behavior.

## Formal Model

The compact K model in `mini-schema-editor.k` abstracts a field to:

* quoted column name;
* field path;
* positional args;
* database-relevant deconstruction kwargs after the existing base ignored attrs
  are removed;
* `choices`.

This abstraction is property-complete for the reported bug because a passing and
failing implementation differ exactly on whether `choices` is part of the
SQLite comparison.

## Required Behavior

S1. Base behavior preservation:
`choices` remains part of the base comparison, so a choices-only difference is
still classified as alteration by the base editor. This preserves non-SQLite
custom enum-like field behavior.

S2. SQLite choices-only no-op:
SQLite ignores `choices` in the `_field_should_be_altered()` comparison. If
quoted column, path, args, and all other database-relevant deconstruction kwargs
are equal, the decision is false even when `choices` differs.

S3. SQLite real schema changes still alter:
SQLite must still return true when a non-ignored deconstruction component or the
quoted column differs, including when `choices` also differs.

S4. Existing ignored attributes are preserved:
The base ignored-attribute set is unchanged from the pre-fix local list. V2 only
moves that list into a private class attribute so SQLite can extend it.

S5. Compatibility frame:
No public method signatures, SQL templates, migration operation APIs, or test
files are changed.

## Adequacy

The formal claims in `schema-editor-spec.k` paraphrase directly to S1-S3. The
remaining obligations S4-S5 are static source/compatibility obligations captured
in `PROOF_OBLIGATIONS.md`.

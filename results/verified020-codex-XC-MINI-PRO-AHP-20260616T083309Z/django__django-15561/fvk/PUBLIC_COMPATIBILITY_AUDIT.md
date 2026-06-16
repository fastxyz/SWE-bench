# Public Compatibility Audit

Status: static audit only; no code was executed.

## Changed symbols

* `BaseDatabaseSchemaEditor._field_should_be_altered_non_database_attrs`
  * New private class attribute holding the pre-existing ignored-attribute list.
  * No public method signature changed.
  * Replaces V1's public-looking `non_database_attrs` name.

* `DatabaseSchemaEditor._field_should_be_altered_non_database_attrs` in the
  SQLite backend
  * Private class attribute extending the base tuple with `choices`.
  * No public method signature changed.

## Public callsites and overrides

* `_field_should_be_altered(old_field, new_field)` keeps the same signature.
* `alter_field(model, old_field, new_field, strict=False)` keeps the same
  signature.
* No SQL template names or migration operation APIs changed.

## Verdict

Pass. V2 keeps the behavior extension subclass-local and private, with no
public callsite or override updates required.

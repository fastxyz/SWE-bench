# PUBLIC COMPATIBILITY AUDIT

Status: constructed, not machine-checked.

## Changed Public Symbols

None. The V1 fix changes SQL string construction inside
`DatabaseWrapper.check_constraints()` but does not change the method name,
signature, return type, exception type, or public call protocol.

## Callers Checked

- `django.core.management.commands.loaddata.Command.loaddata()` passes raw
  `model._meta.db_table` names and continues to call
  `connection.check_constraints(table_names=table_names)` unchanged.
- `django.db.backends.base.creation.BaseDatabaseCreation.deserialize_db_from_string()`
  passes raw model table names and continues to call
  `self.connection.check_constraints(table_names=table_names)` unchanged.
- `django.test.testcases` can call `connection.check_constraints()` with no
  table list; the `table_names=None` path is unchanged.
- `django.db.backends.sqlite3.schema.DatabaseSchemaEditor` can call
  `self.connection.check_constraints()` with no table list; the
  `table_names=None` path is unchanged.

## Override/Subclass Compatibility

The backend method implementation changed internally only. No virtual dispatch
call was given new arguments, and no subclass override signature is affected.

## Result

Public compatibility passes. No production caller edit is required.

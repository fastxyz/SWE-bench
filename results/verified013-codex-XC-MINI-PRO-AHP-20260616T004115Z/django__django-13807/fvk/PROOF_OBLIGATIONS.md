# PROOF OBLIGATIONS

Status: constructed, not machine-checked.

## PO1 - Per-table foreign_key_check quotes table names

For every table name `T` supplied through `table_names`, including SQL keywords,
the specific-table PRAGMA must be constructed using `quote_name(T)`.

- Source: I1, I2, I4, I5.
- Candidate code: `cursor.execute('PRAGMA foreign_key_check(%s)' %
  quote_name(table_name))`.
- Discharge status: discharged by source inspection and modeled by claim
  `V1_FK_CHECK_KEYWORD_SAFE`.

## PO2 - Violation foreign_key_list quotes returned table names

For every violation tuple `(T, rowid, referenced_table_name,
foreign_key_index)`, the follow-up `foreign_key_list` PRAGMA must be
constructed using `quote_name(T)`.

- Source: I3, I4.
- Candidate code: `quoted_table_name = quote_name(table_name)` followed by
  `PRAGMA foreign_key_list(%s)` using `quoted_table_name`.
- Discharge status: discharged by source inspection and modeled by claim
  `V1_VIOLATION_KEYWORD_SAFE`.

## PO3 - Diagnostic SELECT quotes SQL identifiers

For every violation, the diagnostic `SELECT` must treat the offending table,
primary key column, and foreign key column as SQL identifiers.

- Source: I1 and I6, plus proof-derived Finding F3.
- Candidate code: the `SELECT` interpolates `quote_name(primary_key_column_name)`,
  `quote_name(column_name)`, and `quoted_table_name`.
- Discharge status: discharged by source inspection and modeled by claim
  `V1_VIOLATION_KEYWORD_SAFE`.

## PO4 - Database-wide check remains unchanged

When `table_names is None`, the SQLite backend must continue using
`PRAGMA foreign_key_check` without a table argument.

- Source: existing public API semantics and implementation path.
- Candidate code: the `table_names is None` branch is unchanged.
- Discharge status: discharged by diff inspection.

## PO5 - Error-reporting semantics are preserved

Quoting SQL identifiers must not quote the human-readable table and column names
in the `IntegrityError` message.

- Source: I6.
- Candidate code: the exception message still interpolates raw `table_name`,
  `column_name`, `referenced_table_name`, and `referenced_column_name`.
- Discharge status: discharged by source inspection.

## PO6 - Public compatibility is preserved

The repair must not change public method signatures, caller protocols, or test
files.

- Source: I5, benchmark constraints.
- Candidate code: only SQL construction inside the SQLite backend changed.
- Discharge status: discharged by diff and callsite inspection.

## Residual Obligations Not Discharged Here

- Total correctness and performance of `check_constraints()` are not proved.
  The proof is partial correctness over the SQL construction paths relevant to
  the issue.
- The K artifacts were not run through `kompile` or `kprove`; commands are
  supplied in `PROOF.md`.

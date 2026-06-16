# FINDINGS

Status: constructed, not machine-checked.

## F1 - Pre-fix foreign_key_check used raw keyword table names

- Classification: code bug, resolved by V1.
- Public evidence: the issue shows `PRAGMA foreign_key_check(order)` followed
  by `sqlite3.OperationalError: near "order": syntax error`.
- Input: SQLite `check_constraints(table_names=["order"])`, where `order` is a
  SQL keyword table name.
- Observed before V1: SQL was constructed as `PRAGMA foreign_key_check(order)`,
  so SQLite parsed `order` as syntax instead of an identifier.
- Expected: SQL must be constructed with the table name quoted by the SQLite
  backend, equivalent to `PRAGMA foreign_key_check("order")`.
- V1 status: resolved at
  `repo/django/db/backends/sqlite3/base.py` by applying
  `self.ops.quote_name(table_name)` in the specific-table
  `foreign_key_check` path.
- Proof obligation: PO1.

## F2 - Violation reporting also needs quoted table operands

- Classification: proof-derived completeness check, resolved by V1.
- Public evidence: the issue also points to `PRAGMA foreign_key_list(%s)` in
  the same `check_constraints()` function.
- Input: SQLite reports a foreign-key violation for table `order`.
- Observed before V1: the follow-up SQL would be
  `PRAGMA foreign_key_list(order)`, which has the same keyword parsing defect.
- Expected: the follow-up PRAGMA must use the quoted table identifier,
  equivalent to `PRAGMA foreign_key_list("order")`.
- V1 status: resolved by introducing `quoted_table_name =
  quote_name(table_name)` before constructing the `foreign_key_list` query.
- Proof obligation: PO2.

## F3 - Diagnostic SELECT would otherwise reintroduce the same identifier class

- Classification: proof-derived completeness check, resolved by V1.
- Public evidence: `check_constraints()` promises to report the row and column
  involved in an invalid foreign key after constraints were disabled.
- Input: SQLite reports a violation for a reserved-word table or column name.
- Observed before V1: after fixing the PRAGMAs alone, the diagnostic query
  would still have needed to select from the offending table and columns. Raw
  identifiers in that query could fail for the same reason.
- Expected: the diagnostic `SELECT` must quote the table, primary key column,
  and foreign key column while preserving raw names in the exception message.
- V1 status: resolved by quoting those SQL identifiers in the `SELECT` and
  leaving the message interpolation unchanged.
- Proof obligations: PO3, PO5.

## F4 - No unresolved source finding from the FVK audit

- Classification: confirmation.
- Evidence: the remaining reachable paths in the modern SQLite branch are:
  database-wide `PRAGMA foreign_key_check` with no table operand,
  per-table `foreign_key_check` with `quote_name(table_name)`,
  violation-reporting `foreign_key_list` with the same quoted table name, and
  diagnostic `SELECT` with quoted table/column identifiers.
- Decision: V1 stands. No additional production code edit is justified by the
  current public intent and proof obligations.
- Proof obligations: PO1 through PO6.

## F5 - Machine checking was not executed

- Classification: proof capability gap required by the benchmark constraints.
- Input: FVK commands `kompile` and `kprove`.
- Observed: commands were written into the artifacts but not executed.
- Expected in this session: do not run K tooling or tests.
- Impact: the proof is constructed, not machine-checked. This does not change
  the source decision, but it conditions any test-redundancy recommendation.

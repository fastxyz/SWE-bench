# FORMAL SPEC ENGLISH

Status: constructed, not machine-checked.

## PRE_FIX_REPRODUCES_BUG

If a table name is a SQL keyword and it is inserted raw into a
`foreign_key_check` table operand, the abstract SQLite parser reaches `ERR`.
This models the issue's `PRAGMA foreign_key_check(order)` syntax failure.

## V1_FK_CHECK_KEYWORD_SAFE

For any table-name class, keyword or non-keyword, V1 quotes the table name
before constructing the specific-table `foreign_key_check` query, so the
abstract parser reaches `OK`.

## V1_VIOLATION_KEYWORD_SAFE

For any table-name, primary-key-column, and foreign-key-column classes, V1
quotes every identifier used by the violation-reporting PRAGMA and diagnostic
`SELECT`, so the abstract parser reaches `OK`.

## V1_NONKEYWORD_PRESERVED

For a non-keyword table name, V1's no-violation path still reaches `OK`.

## Frame Conditions

The formal claims do not change public signatures, exception types, caller
protocols, or the database-wide `table_names=None` branch.

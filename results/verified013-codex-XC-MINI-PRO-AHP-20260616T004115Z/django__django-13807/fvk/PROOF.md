# PROOF

Status: constructed, not machine-checked.

## Claims Proved In The Constructed Model

The model in `mini-sqlite-check-constraints.k` classifies names as `kw` or
`nonkw`, and as `raw(Name)` or `quoted(Name)`.

- `raw(kw)` represents the issue's failing `order` table case.
- `quoted(kw)` represents the desired backend-quoted identifier case.
- `raw(nonkw)` represents legacy non-keyword behavior.

The spec in `sqlite-check-constraints-spec.k` contains these relevant claims:

- `PRE_FIX_REPRODUCES_BUG`: a raw keyword in `foreign_key_check` reaches
  `ERR`.
- `V1_FK_CHECK_KEYWORD_SAFE`: V1's no-violation per-table path reaches `OK`
  for any name class, including `kw`.
- `V1_VIOLATION_KEYWORD_SAFE`: V1's violation-reporting path reaches `OK`
  for any table, primary key column, and foreign key column name class.
- `V1_NONKEYWORD_PRESERVED`: V1's no-violation path also reaches `OK` for
  non-keyword table names.

## Constructed Proof Sketch

1. Pre-fix reproduction:
   - Input class `kw`.
   - Pre-fix construction uses `raw(kw)` for `foreign_key_check`.
   - `parseIdent(raw(kw)) => ERR`.
   - Therefore the path reaches `ERR`, matching the issue's
     `PRAGMA foreign_key_check(order)` syntax error.

2. V1 per-table check:
   - Input class `N`, where `N` ranges over `kw` and `nonkw`.
   - V1 construction applies `quote(N)`.
   - `quote(N) => quoted(N)`.
   - `parseIdent(quoted(N)) => OK` for both name classes.
   - Therefore `checkFK(quote(N)) => OK`.

3. V1 violation-reporting path:
   - Input classes `T`, `PK`, and `FK` range over `kw` and `nonkw`.
   - V1 applies `quote(T)` to `foreign_key_check`.
   - V1 applies `quote(T)` to `foreign_key_list`.
   - V1 applies `quote(T)`, `quote(PK)`, and `quote(FK)` to the diagnostic
     `SELECT`.
   - Every parsed identifier is `quoted(_)`, and every `quoted(_)` identifier
     parses as `OK`.
   - Sequential composition with `andThen` preserves `OK` across all three SQL
     construction checks.

4. Database-wide branch:
   - The branch for `table_names is None` has no table operand and is unchanged.
   - The issue's malformed identifier class cannot occur in that SQL string.

5. Public compatibility:
   - The method name, arguments, return behavior, exception type, and callers
     are unchanged.
   - The proof only justifies SQL identifier quoting, not any public API change.

## Residual Risk

- Partial correctness only: termination and database performance are not proved.
- The mini-K model abstracts SQLite parsing to the keyword/non-keyword and
  quoted/raw distinction. This abstraction is adequate for the reported defect
  because it distinguishes the concrete failing representative `order` from
  the quoted passing representative.
- The proof is constructed, not machine-checked, because this session forbids
  K tooling.

## Commands To Machine-Check Later

Do not run these in this benchmark session. They are the commands a human could
run in an environment with K installed:

```sh
kompile fvk/mini-sqlite-check-constraints.k --backend haskell
kast --backend haskell fvk/sqlite-check-constraints-spec.k
kprove fvk/sqlite-check-constraints-spec.k
```

Expected result after successful machine checking: `#Top` for all claims.

## Test Recommendation

No tests were edited. If machine checking and normal Django test execution were
available, a regression test should keep coverage for:

- loading a fixture for a model whose `db_table` is `order`;
- checking violation reporting for a reserved-word table name, if a focused
  fixture can create an invalid foreign key row.

No test removal is recommended from this constructed proof alone.

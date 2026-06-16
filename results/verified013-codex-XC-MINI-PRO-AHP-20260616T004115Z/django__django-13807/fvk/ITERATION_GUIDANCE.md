# ITERATION GUIDANCE

Status: constructed, not machine-checked.

## V2 Decision

V1 stands unchanged.

The audit found the original defect and two reachable completeness obligations:
quote the specific-table `foreign_key_check`, quote the violation
`foreign_key_list`, and quote identifiers in the diagnostic `SELECT`. V1 already
does all three. No additional production edit is justified by the public intent
or proof obligations.

## Change Guidance

- Keep the source change in `repo/django/db/backends/sqlite3/base.py`.
- Do not move quoting to `loaddata`; callers pass raw model table names and the
  backend owns identifier quoting.
- Do not replace `self.ops.quote_name()` with hard-coded punctuation; public
  hints and backend conventions point to `quote_name()`.
- Keep the raw table and column names in the `IntegrityError` message; only SQL
  identifiers need quoting.

## Test Guidance For A Normal Environment

Do not run these in this benchmark session.

- Add or keep a regression test that loads a fixture for a model with
  `db_table = "order"` on SQLite.
- If practical, add or keep a focused violation-reporting test that exercises a
  reserved-word table name after `foreign_key_check` returns a violation.
- Keep broader integration tests around fixture loading; the constructed proof
  covers only the identifier-quoting property in this backend method.

## Machine-Check Guidance

The FVK proof remains constructed until K tooling is run:

```sh
kompile fvk/mini-sqlite-check-constraints.k --backend haskell
kast --backend haskell fvk/sqlite-check-constraints-spec.k
kprove fvk/sqlite-check-constraints-spec.k
```

Expected result after successful machine checking: `#Top`.

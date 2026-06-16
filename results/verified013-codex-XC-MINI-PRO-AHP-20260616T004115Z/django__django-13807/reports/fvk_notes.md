# FVK Notes

## Decision

V1 stands unchanged.

The FVK audit found no unresolved source defect after checking the full
identifier-quoting behavior required by the issue. The relevant findings are
F1 through F4 in `fvk/FINDINGS.md`, and the obligations are PO1 through PO6 in
`fvk/PROOF_OBLIGATIONS.md`.

## Trace From Findings To Source Decision

- F1 identified the original crash: `foreign_key_check(order)` treats `order`
  as syntax. PO1 requires applying `self.ops.quote_name(table_name)` in the
  per-table `foreign_key_check` path. V1 already does this, so no V2 source
  edit is needed.
- F2 identified the same problem in the reachable violation-reporting
  `foreign_key_list` path. PO2 requires quoting the returned violation table
  name before that PRAGMA. V1 already does this with `quoted_table_name`.
- F3 checked the follow-up diagnostic query instead of stopping at the lines
  named by the issue. PO3 requires quoting the table, primary key column, and
  foreign key column in the diagnostic `SELECT`; PO5 requires preserving raw
  names in the `IntegrityError` text. V1 already satisfies both.
- F4 records the no-unresolved-finding conclusion. PO4 confirms the
  database-wide `table_names=None` branch remains unchanged, and PO6 confirms
  no public API/callsite/test-file change is needed.

## Formalization And Proof Status

The formal model abstracts SQLite identifiers into keyword and non-keyword
classes, plus raw vs quoted occurrence. That abstraction is enough for this
defect because it distinguishes the failing representative `raw(kw)` from the
passing representative `quoted(kw)`. The constructed proof in `fvk/PROOF.md`
shows that V1 reaches `OK` for keyword table names in both the no-violation and
violation-reporting paths.

No tests, Python, or K tooling were run. F5 records this as a proof capability
gap required by the benchmark constraints, not as a source-code problem.

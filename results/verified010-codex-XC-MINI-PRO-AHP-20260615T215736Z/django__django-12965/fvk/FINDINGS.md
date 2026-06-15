# FVK Findings

Status: constructed, not machine-checked. Findings are based on public intent and static source reasoning; no tests or code were run.

## F1: V1 fixed the reported empty-alias symptom but did not match Django's alias initialization invariant

Input/state: a delete query with `alias_map` present but all alias refcounts zero, and no `extra_tables`.

Observed in V1: `single_alias` only initialized the base alias when `alias_map` was empty. If `alias_map` was non-empty but inactive, it returned `False`, sending the delete to fallback.

Expected: source evidence E6 shows `SQLCompiler.setup_query()` initializes the base alias whenever all alias refcounts are zero. For delete compilation, the equivalent normalized state is one active base alias, so a query with no other active contributors should be direct.

Classification: code bug in V1 relative to the compiler invariant.

Resolution in V2: `single_alias` now calls `get_initial_alias()` when all alias refcounts are zero, not only when `alias_map` is empty.

Trace: proof obligations PO2 and PO3.

## F2: V1 over-broadened direct delete for `extra_tables`

Input/state: a delete query with no active aliases before setup, but with `query.extra_tables` populated.

Observed in V1: `single_alias` initialized the base alias and returned `True`, because it counted exactly one active alias and ignored `extra_tables`.

Expected: `extra_tables` are additional `FROM` contributors in normal SELECT compilation, while `_as_sql()` emits only `DELETE FROM base_table` and a `WHERE` clause. A query with `extra_tables` cannot be safely classified as a direct single-table delete by this branch.

Classification: code bug introduced by V1's incomplete predicate.

Resolution in V2: `single_alias` now requires `not self.query.extra_tables`.

Trace: proof obligations PO5 and PO6.

## F3: Reported `Model.objects.all().delete()` regression is discharged by V2

Input/state: fast-delete queryset for `Model.objects.all().delete()`, before any alias is initialized: `activeAliases = 0`, `extraTables = 0`.

Observed before fix: the delete compiler treated the query as not single-alias and produced fallback SQL with a self-subquery.

Expected: direct `DELETE FROM <base_table>`.

Resolution in V2: alias normalization changes the state to one active base alias; because `extra_tables` is empty, `single_alias` returns `True` and `as_sql()` takes `_as_sql(self.query)`.

Trace: proof obligations PO1, PO2, PO3, and PO4.

## Residual risks and test guidance

- The proof is constructed, not machine-checked. Keep all tests until the emitted `kprove` command returns `#Top`.
- Add or keep a SQL-shape regression test for `Model.objects.all().delete()` asserting the generated delete is direct and contains no self-subquery.
- Add or keep a compatibility test for a delete query involving `extra(tables=...)` or other additional table contributors, if the public suite has a suitable model, to ensure the direct branch is not over-applied.

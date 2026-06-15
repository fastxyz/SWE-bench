# FVK Spec

Status: constructed, not machine-checked.

## Unit Under Audit

The audited unit is the branch decision in `SQLDeleteCompiler`:

- `SQLDeleteCompiler.single_alias` in `repo/django/db/models/sql/compiler.py`;
- the `if self.single_alias: return self._as_sql(self.query)` branch in `SQLDeleteCompiler.as_sql()`;
- the MySQL subclass only as a compatibility caller of the same property.

The observable is SQL shape: direct single-table delete versus fallback delete.

## Public Intent Ledger

See `fvk/PUBLIC_EVIDENCE_LEDGER.md`. Critical obligations:

- E1-E4 require `Model.objects.all().delete()` to produce direct `DELETE FROM <table>` instead of a self-subquery.
- E5 limits the direct branch to a single-alias delete and requires a backend-neutral fix.
- E6 shows the compiler setup invariant: when no alias has an active refcount, the base table alias must be initialized before counting aliases.
- E7 shows a compatibility constraint: `extra_tables` are added by `get_from_clause()` but are not representable by `_as_sql()`, so they must prevent the direct branch.

## Formal State

The model abstracts a delete query to:

- `activeAliases`: the number of aliases in `query.alias_map` with refcount greater than zero before the delete branch decision;
- `extraTables`: the number of explicit `query.extra_tables` entries.

The abstraction is property-complete for this issue because the disputed behavior is whether a query with only the base table is sent to direct SQL or fallback SQL. Table names, quoting, parameter binding, and row counts are intentionally outside this proof.

## Contract

Before deciding direct versus fallback:

1. If `activeAliases == 0`, normalize the query by initializing the base table alias. The normalized active alias count is then `1`.
2. The delete is direct iff the normalized active alias count is exactly `1` and `extraTables == 0`.
3. Otherwise, the delete must stay on the existing fallback path.

## K Artifacts

- `fvk/mini-django-delete.k`: minimal K semantics for the branch decision.
- `fvk/django-delete-spec.k`: K claims for direct and fallback obligations.

The exact commands that a human could run later are recorded in `fvk/PROOF.md`; they were not executed in this session.

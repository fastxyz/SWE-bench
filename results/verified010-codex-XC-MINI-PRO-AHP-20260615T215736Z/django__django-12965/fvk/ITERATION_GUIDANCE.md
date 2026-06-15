# Iteration Guidance

Status: V2 source edit applied; no test or formal-tool execution performed.

## Code guidance

Keep the V2 source change in `repo/django/db/models/sql/compiler.py`.

The FVK audit found two V1 issues:

- F1: alias initialization should follow the existing compiler invariant for all-zero alias refcounts, not only empty `alias_map`;
- F2: `extra_tables` must prevent the direct delete branch.

Both are addressed by the V2 predicate:

```python
if all(self.query.alias_refcount[a] == 0 for a in self.query.alias_map):
    self.query.get_initial_alias()
active_alias_count = sum(
    self.query.alias_refcount[t] > 0 for t in self.query.alias_map
)
return active_alias_count == 1 and not self.query.extra_tables
```

## Verification guidance

When an execution environment exists, run the Django tests relevant to delete SQL generation and query compiler behavior. Also machine-check the constructed proof:

```sh
cd fvk
kompile mini-django-delete.k --backend haskell
kast --backend haskell django-delete-spec.k
kprove django-delete-spec.k
```

Expected proof result: `#Top`.

## Test guidance

Do not remove tests based on this constructed proof alone.

Useful test cases:

- `Model.objects.all().delete()` on a fast-delete model emits direct `DELETE FROM <table>`.
- A single-table filtered fast delete remains direct.
- A delete involving joined aliases remains on fallback SQL.
- A delete involving `extra(tables=...)` does not take the direct `_as_sql()` branch.

## Residual risk

The mini-K model abstracts SQL text and backend details to a two-valued shape, `direct` versus `fallback`. That is adequate for the reported regression, but it does not prove quoting, parameters, row counts, backend-specific multi-table syntax, or transaction behavior.

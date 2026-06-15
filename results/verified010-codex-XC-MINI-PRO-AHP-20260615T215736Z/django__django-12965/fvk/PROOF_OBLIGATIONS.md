# Proof Obligations

Status: constructed, not machine-checked.

## PO1: Public intent adequacy

The formal claims must express the public issue, not V1 behavior. Specifically, `Model.objects.all().delete()` must be direct and must not use a self-subquery.

Status: discharged by claims `deleteShape(0, 0) => direct` and `deleteShape(1, 0) => direct`, with provenance E1-E5.

## PO2: Alias normalization

If no aliases are active before delete compilation, the compiler must initialize the base table alias before counting single-table status.

Status: discharged by V2 source:

```python
if all(self.query.alias_refcount[a] == 0 for a in self.query.alias_map):
    self.query.get_initial_alias()
```

This mirrors `SQLCompiler.setup_query()` and covers both empty `alias_map` and non-empty but inactive `alias_map`.

## PO3: Direct-delete predicate

After alias normalization, direct delete is allowed only when exactly one alias is active.

Status: discharged by V2 source:

```python
active_alias_count = sum(
    self.query.alias_refcount[t] > 0 for t in self.query.alias_map
)
```

and the return condition `active_alias_count == 1`.

## PO4: Reported all-delete case

For `activeAliases = 0` and no extra tables, `single_alias` must be true and `as_sql()` must call `_as_sql(self.query)`.

Status: discharged by PO2 plus PO3 and K claim `deleteShape(0, 0) => direct`.

## PO5: Extra-table exclusion

If `query.extra_tables` is non-empty, direct `_as_sql()` is not a valid representation because `_as_sql()` emits no `FROM` clause for those tables.

Status: discharged by V2 source condition `not self.query.extra_tables` and K claim `extraTables > 0 -> fallback`.

## PO6: Multi-alias fallback preservation

If two or more aliases are active after normalization, the compiler must not use direct `_as_sql()`.

Status: discharged by `active_alias_count == 1` and K claim `activeAliases >= 2 -> fallback`.

## PO7: Backend compatibility

The fix must remain backend-neutral and must not bypass MySQL's existing fallback for multi-table delete when self-select is unavailable.

Status: discharged by changing only the base `SQLDeleteCompiler.single_alias` property. The MySQL subclass still uses `self.single_alias` and otherwise retains its backend-specific `DELETE alias FROM ...` fallback.

## PO8: Public API compatibility

No public API signature, return type, or test file should change.

Status: discharged by static diff: only the body of an internal cached property changed; tests were not edited.

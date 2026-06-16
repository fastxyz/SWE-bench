# FVK Proof

Status: constructed, not machine-checked. No tests, Python, `kompile`, `kast`, or `kprove` were run.

## Claims

The formal claims are recorded in `fvk/django-15629-spec.k` over the abstract semantics in `fvk/mini-django-schema.k`.

Claim 1 proves PO1: `fkParams()` returns a parameter record whose collation is the target parameter collation.

Claim 2 proves PO2: the column-SQL abstraction receives and emits the FK collation supplied by PO1.

Claim 3 proves PO3: a retained primary key or unique field with a changed collation satisfies `dropIncomingFks(old, new) == true`.

Claim 4 proves PO4: a related FK field with a new collation produces an alter abstraction containing that collation while retaining the field's nullability flag.

There are no loops in the modeled transition fragment, so no loop circularity is required. Termination is out of scope; the proof is a partial-correctness proof over schema-editor transition decisions and emitted column-definition components.

## Constructed Proof Sketch

### PO1

Starting from the V1 source:

```python
target_db_parameters = self.target_field.db_parameters(connection=connection)
return {
    "type": self.db_type(connection),
    "check": self.db_check(connection),
    "collation": target_db_parameters.get("collation"),
}
```

Symbolic execution of `ForeignKey.db_parameters()` leaves the existing type and check expressions unchanged and projects the target collation from target parameters. This matches intent evidence E2-E3 and K claim 1.

### PO2

`column_sql()` computes `field_db_params = field.db_parameters(...)` and passes it to `_iter_column_sql()`. `_iter_column_sql()` yields the column type and then yields `_collate_sql(collation)` exactly when `field_db_params.get("collation")` is truthy. By PO1, an FK to a collated target supplies that truthy value. Therefore create-model and add-field FK column SQL include the target collation. This matches K claim 2.

### PO3

The pre-V1 guard was equivalent to:

```text
retained_pk_or_unique(old, new) and old_type != new_type
```

V1 changes it to:

```text
retained_pk_or_unique(old, new)
and (old_type != new_type or old_collation != new_collation)
```

For a collation-only change, `old_type == new_type` and `old_collation != new_collation`. Boolean simplification gives `true` for the second disjunct, so incoming FKs are dropped and related columns enter `rels_to_update`. This matches K claim 3 and discharges E4.

### PO4

For each `(old_rel, new_rel)` in `rels_to_update`, V1 computes:

```python
rel_db_params = new_rel.field.db_parameters(connection=self.connection)
rel_type = rel_db_params["type"]
rel_collation = rel_db_params.get("collation")
if rel_collation:
    rel_type = "%s %s" % (rel_type, self._collate_sql(rel_collation))
fragment, other_actions = self._alter_column_type_sql(
    new_rel.related_model, old_rel.field, new_rel.field, rel_type
)
```

By PO1, `new_rel.field.db_parameters()["collation"]` is the new target collation. The alter helper receives a type string containing that collation. On MySQL, the existing override appends `NULL` or `NOT NULL` from `old_rel.field`, so the generated related-column `MODIFY` still carries nullability. This proves the issue's two examples: a non-null FK receives collated type plus `NOT NULL`, and a nullable FK receives collated type plus `NULL`.

### PO5

The proof frame is checked by diff and callsite inspection:

- no test files changed;
- no method signature changed;
- `ForeignKey.db_type()` still delegates to `target_field.rel_db_type()`;
- FK `"check"` still comes from `ForeignKey.db_check()`;
- existing constraint drop/recreate helpers remain in place.

This establishes that the fix is targeted to collation propagation.

## Adequacy Check

The public symptom is MySQL rejecting FK constraint creation because the referenced PK and referencing FK columns do not have matching collations. The proof covers both contributors to that symptom:

1. FK column metadata for creation/add-field SQL.
2. The referenced-target alter path that updates existing related columns before constraints are recreated.

The proof intentionally does not claim exact SQL text order, live database execution, migration autodetector completeness, or all backend grammar details.

## Commands to Machine-Check Later

These commands are emitted for reproducibility only. They were not run.

```sh
kompile fvk/mini-django-schema.k --backend haskell
kast --backend haskell fvk/django-15629-spec.k
kprove fvk/django-15629-spec.k
```

Expected result under the abstract fragment: all claims discharge to `#Top`.

## Test Recommendation

No tests were edited. Because the proof is constructed but not machine-checked and abstracts backend execution, no existing tests should be removed. Tests that would be useful to keep or add are listed in `fvk/ITERATION_GUIDANCE.md`.

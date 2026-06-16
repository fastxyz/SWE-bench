# PROOF

Status: constructed, not machine-checked.

## Claim summary

The formal core is in:

- `fvk/mini-python.k`
- `fvk/rename-index-spec.k`

The central claim is:

`reverse-old-fields-restores-generated-name`

For any target model table and old field set, if the database currently contains
the renamed index `NEW` and migration is allowed, `reverseOldFields()` rewrites
the database state to contain `generatedIdxName(TABLE, FIELDS)`.

This corresponds to PO1.

The second claim is:

`round-trip-reapply-safe`

Starting from the generated name, forwards renames it to `NEW`, backwards
renames it back to the generated name, and forwards renames it to `NEW` again.
The middle step prevents the third forwards from being a rename-to-self.

This corresponds to PO2.

## Constructed proof sketch

1. Start in the `old_fields` backwards branch.
2. The `allow_migrate_model()` guard case-splits:
   - If false, the rule `reverseOldFields(..., false)` leaves the database
     unchanged. This proves PO3.
   - If true, execution continues to the name reconstruction branch.
3. The target-state model supplies the table name and field-to-column mapping.
   In the abstraction, this is the `model(TABLE, MODELNAME, FIELDS)` term.
4. `_create_index_name(TABLE, COLUMNS, suffix="_idx")` is represented by
   `generatedIdxName(TABLE, FIELDS)`. The abstraction preserves the property
   that matters for the bug: this value is distinct from `NEW`.
5. V1 constructs:
   - `old_index = Index(fields=old_fields, name=NEW)`
   - `new_index = Index(fields=old_fields, name=GENERATED)`
6. `schema_editor.rename_index(model, old_index, new_index)` transitions the
   database name from `NEW` to `GENERATED`. This proves PO1 and PO4.
7. For the forwards/backwards/forwards sequence, compose the transition rules:
   - `forwardOldFields(..., NEW, true)` maps `GENERATED -> NEW`.
   - `reverseOldFields(..., NEW, true)` maps `NEW -> GENERATED`.
   - `forwardOldFields(..., NEW, true)` maps `GENERATED -> NEW`.
8. Because the third step starts from `GENERATED`, not `NEW`, it is not the
   reported PostgreSQL self-rename path. This proves PO2.

## Adequacy check

The proof models only the database-visible index name transition. It abstracts
away the full Django model registry, SQL generation, connection objects, and
backend DDL syntax. This is adequate for the reported issue because the failure
depends on one observable value: which index name exists after backwards.

The abstraction keeps the discriminating behavior:

- Legacy behavior: backwards leaves `db(NEW)`.
- Required behavior: backwards leaves `db(GENERATED)`.

An abstraction that represented only "some index exists" would be inadequate;
this proof does not use that abstraction.

## Test guidance

Do not delete tests. The proof is constructed only and the task forbids running
the K toolchain.

Conditionally, after machine-checking, an in-domain test that applies
forwards/backwards/forwards to a simple `index_together` rename would be
subsumed by PO1 and PO2. Integration tests covering backend introspection,
schema-editor SQL, and migration executor wiring should remain.

## Commands not run

The following commands are the intended machine-check commands. They were not
run in this session.

```sh
kompile fvk/mini-python.k --backend haskell
kast --backend haskell fvk/rename-index-spec.k
kprove fvk/rename-index-spec.k
```

Expected result after installing and running the K toolchain: `#Top` for all
claims.

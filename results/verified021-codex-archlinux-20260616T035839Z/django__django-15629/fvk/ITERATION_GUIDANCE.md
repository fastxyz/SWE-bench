# FVK Iteration Guidance

Status: constructed, not machine-checked.

## V2 Decision

V1 stands unchanged. The FVK audit did not identify a production-code defect beyond the two gaps V1 already addressed:

- F1/PO1-PO2: FK metadata now propagates target collation into create/add column SQL.
- F2-F3/PO3-PO4: referenced PK/unique type or collation changes now update related FK columns and constraints.

No additional source edits are justified by the current public intent and proof obligations.

## Tests to Keep or Add

Do not remove any tests based on this constructed proof. Useful public or hidden test shapes for a conventional test pass would be:

1. Creating models from scratch where a `ForeignKey` and `OneToOneField` target a `CharField(primary_key=True, db_collation=...)`; FK columns should include the target collation.
2. Altering a primary key from an integer/auto field to a collated char field with one non-null and one nullable incoming FK; related alter SQL should include collation and preserve nullability.
3. Adding, changing, and removing `db_collation` on an already-text primary key or unique `to_field`; related FK constraints should be dropped/rebuilt and columns altered.
4. Verifying that FK type selection still uses `target_field.rel_db_type()` for backend-specific integer behavior.
5. Verifying that target check constraints are not copied onto FK columns.

## Residual Risks

- The proof is not machine-checked.
- The K model abstracts SQL string ordering and database grammar.
- Live backend behavior, especially MySQL acceptance of the exact emitted SQL, remains an integration-test concern.
- If a project uses different table defaults after removing an explicit `db_collation`, Django still has no field-level explicit target default to mirror; this is outside the public issue unless a target collation is explicitly configured.

## Next Human Commands

When an execution environment exists, run the Django test subset that exercises schema editor collation behavior and, separately, machine-check or repair the FVK K files:

```sh
kompile fvk/mini-django-schema.k --backend haskell
kast --backend haskell fvk/django-15629-spec.k
kprove fvk/django-15629-spec.k
```

These commands are documentation only in this task; they were not executed.

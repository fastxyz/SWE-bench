# ITERATION_GUIDANCE

Status: constructed, not machine-checked.

## Code Outcome

V1 was not accepted unchanged. The FVK audit found two compatibility risks:

- F-002: V1 resolved conflict option names outside `OnConflict.UPDATE`.
- F-003: V1 passed generator expressions to backend conflict SQL hooks.

V2 keeps the original column-name fix and adds two refinements:

- Guard name-to-field conversion in `bulk_create()` with
  `on_conflict == OnConflict.UPDATE`.
- Materialize column-name lists in `SQLInsertCompiler` before calling
  `on_conflict_suffix_sql()` on the update-conflict path.

## Next Verification Steps

When an execution environment exists, run the Django test subset that covers
bulk create upserts and custom `db_column` mappings. Do not delete tests unless
the constructed K proof has also been machine-checked.

Suggested commands for a future environment, not run here:

```sh
python runtests.py bulk_create custom_columns
kompile fvk/mini-django-upsert.k --main-module MINI-DJANGO-UPSERT --syntax-module MINI-DJANGO-UPSERT-SYNTAX --backend haskell
kast --definition mini-django-upsert-kompiled fvk/django-bulk-create-conflict-spec.k
kprove fvk/django-bulk-create-conflict-spec.k --definition mini-django-upsert-kompiled
```

## Tests to Add or Keep

Recommended future regression coverage:

- Keep existing `bulk_create` update-conflict tests.
- Add or keep a regression test with `db_column` values whose spelling or case
  differs from model field names, using both `update_fields` and `unique_fields`.
- Keep `unique_fields=["pk"]` coverage, because the proof treats that as a frame
  condition.
- Keep backend integration tests, because the FVK model proves identifier flow
  but does not execute SQL against a database.

## Open Questions

No user clarification is required for the audited issue. The public intent is
specific: conflict SQL must use database column names.

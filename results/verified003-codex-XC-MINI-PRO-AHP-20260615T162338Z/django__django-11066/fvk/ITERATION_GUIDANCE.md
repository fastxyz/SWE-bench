# FVK Iteration Guidance

Status: constructed, not machine-checked.

## Decision

V1 stands unchanged.

The FVK audit identified the same root cause as the baseline pass: the model save must receive the migration database alias explicitly. The current source already does that:

```python
content_type.save(using=db, update_fields={'model'})
```

No additional source change is justified by the public intent ledger or proof obligations.

## Why No Further Code Edit Was Made

F-3 and PO-3 establish that the explicit `using=db` argument reaches `Model.save()` and then `_save_table()` as the update alias. F-4 and PO-4 through PO-7 establish that the surrounding no-op and conflict branches remain unchanged. F-5 and PO-8 establish that the call uses an existing public keyword and does not require a compatibility shim.

Replacing the instance save with a manager-level `update()` remains rejected. It could also target `db`, but the audit found no public intent requiring a broader rewrite, and the existing save preserves the established `IntegrityError` handling, signals, and `update_fields` validation path.

## Recommended Follow-Up Test

Add a regression test in the project test suite outside this benchmark run:

1. Configure two aliases, for example `"default"` and `"tenant"`.
2. Configure a router whose write routing for `ContentType` would choose `"default"` if no explicit `using` is passed.
3. Run a migration containing `RenameModel` with the schema editor / migrate command targeting `"tenant"`.
4. Assert the old content type model name is gone from `"tenant"` and the new model name exists on `"tenant"`.
5. Assert the test does not depend on a `django_content_type` table on `"default"`.

This benchmark forbids test edits and execution, so this is guidance only.

## Residual Risk

The proof is constructed, not machine-checked. It relies on the source-level reading of Django's ORM save path and an abstract K model that preserves the database-alias observable. It does not prove full Django ORM semantics, database backend behavior, or migration command execution end to end.

The residual risk does not justify more code changes because the audited code path and public issue both point to the same minimal repair: pass `using=db` to `save()`.

# FVK Notes

## Decision

V1 stands unchanged. The source already contains the change required by the FVK audit:

```python
content_type.save(using=db, update_fields={'model'})
```

## Trace to Findings and Proof Obligations

F-1 and F-2 identify the original defect: the pre-fix save did not carry `using=db`, so `Model.save()` could route the write to `"default"` even though `_rename()` was running for `schema_editor.connection.alias`. PO-1, PO-2, and PO-3 turn that into the core proof obligation.

F-3 confirms V1 satisfies the core obligation. PO-3 traces the explicit alias through `Model.save()` and `_save_table()`, where the update queryset uses `.using(using)`.

F-4 confirms no extra branch changes are needed. PO-4 through PO-7 cover the migration-disallowed, missing-content-type, and `IntegrityError` conflict branches, all of which V1 preserves.

F-5 and PO-8 justify compatibility: `using` is an existing `Model.save()` keyword, so the change does not alter public APIs, migration operation injection, or dispatch signatures.

F-6 and PO-9 record the honesty gate. The proof is constructed but not machine-checked because tests, Python, and K tooling are forbidden in this benchmark phase.

## Rejected Changes

I did not replace the instance save with `ContentType.objects.using(db).filter(...).update(...)`. That alternative could target the correct database, but it would unnecessarily bypass the existing instance-save path and alter more behavior than the public issue requires. The proof obligations only require explicit aliasing of the save.

I did not add or modify tests because the task forbids test changes. `fvk/ITERATION_GUIDANCE.md` records the regression test that should be added in a normal Django development environment.

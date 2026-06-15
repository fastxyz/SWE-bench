# FVK Notes

The FVK audit confirmed the V1 repair strategy and made one small source refactor.

## Source change

Changed `repo/django/db/models/fields/files.py` so `FileField.deconstruct()` handles callable storage with an explicit first branch:

```python
if hasattr(self, '_storage_callable'):
    kwargs['storage'] = self._storage_callable
elif self.storage is not default_storage:
    kwargs['storage'] = self.storage
```

This is traced to F-002 and PO-2/PO-3. The public intent requires deconstruction to return the original callable, including the case where the callable's evaluated runtime storage is `default_storage`. Branching first on `_storage_callable` makes that obligation direct and avoids depending on the evaluated storage value.

## Decisions to keep V1 behavior

Kept the V1 constructor behavior that stores `_storage_callable` before evaluating the callable. This is justified by F-001 and PO-1: runtime behavior still receives the evaluated `Storage` instance, while deconstruction can recover the original callable.

Kept the existing validation that callable storage must return a `Storage` instance. This is justified by PO-6 and preserves pre-existing error behavior.

Kept non-callable explicit storage and default-storage deconstruction behavior unchanged. This is justified by F-003/F-004 and PO-4/PO-5.

Made no changes to `ImageField`. This is justified by F-005 and PO-7 because `ImageField.deconstruct()` already delegates to `FileField.deconstruct()`.

## Verification status

The FVK artifacts are under `fvk/`. The proof is constructed, not machine-checked, and no tests or code were run because the task forbids execution. This is recorded as F-006. The emitted commands in `fvk/PROOF.md` are the expected future machine-check commands, not observed results.

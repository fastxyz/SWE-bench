# FVK Iteration Guidance

Status: V2 is the recommended patch. It is V1 plus a small explicit callable branch in `FileField.deconstruct()`.

## Code Decisions

Keep the V1 design of preserving the callable before evaluating it. This is justified by F-001 and PO-1: runtime state still receives the evaluated `Storage`, while migrations can recover the original callable.

Use an explicit callable branch in `deconstruct()`:

```python
if hasattr(self, '_storage_callable'):
    kwargs['storage'] = self._storage_callable
elif self.storage is not default_storage:
    kwargs['storage'] = self.storage
```

This is justified by F-002 and PO-2/PO-3. It makes callable serialization unconditional on the callable path and avoids relying on the evaluated storage value.

Do not change the non-callable or default-storage branches. This is justified by F-003, F-004, PO-4, and PO-5.

Do not change `ImageField`. This is justified by F-005 and PO-7 because `ImageField.deconstruct()` already delegates to `FileField.deconstruct()`.

## Recommended Future Tests

Do not modify tests in this task. If tests are added later, the highest-value public tests are:

- `FileField(storage=callable_storage).deconstruct()` returns `kwargs["storage"] is callable_storage`.
- The callable is not invoked by `deconstruct()` after construction.
- A callable returning `default_storage` is still serialized as the callable.
- `ImageField(storage=callable_storage).deconstruct()` has the same storage behavior.
- Invalid callable results still raise the existing `TypeError`.

## Non-goals

The FVK audit did not justify changing `storage or default_storage` to a broader explicit-`None` check. That would affect falsey non-`None` storage arguments outside the public issue and is not needed to discharge the callable-storage deconstruction obligations.

## Next Verification Step

In an environment with K installed, run:

```sh
cd fvk
kompile mini-python-filefield.k --backend haskell
kast --backend haskell filefield-storage-spec.k
kprove filefield-storage-spec.k
```

Keep all tests until the constructed claims are machine-checked and broader migration integration behavior is covered.

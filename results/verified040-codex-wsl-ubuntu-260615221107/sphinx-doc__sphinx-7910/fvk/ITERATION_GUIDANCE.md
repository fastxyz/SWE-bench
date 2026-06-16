# Iteration Guidance

Status: V2 source changes applied; no further code edits are justified by the
current FVK findings.

## Code Guidance

Keep the V2 changes in `repo/sphinx/ext/napoleon/__init__.py`:

- `_get_class_from_qualname()` implements module+qualname owner lookup and the
  compatibility fallback for unresolved top-level classes. This addresses F1
  and F3 and discharges PO2, PO3, and PO5.
- `_skip_member()` checks both the resolved class and `unwrap(cls)`. This
  addresses F2 and discharges PO4.
- The original config, module-member, and `__weakref__` gates remain unchanged.
  This addresses F4 and discharges PO1, PO6, PO7, and PO8.

## Tests To Add Or Keep

Do not modify tests in this task.

Recommended future tests:

- A decorated `__init__` whose decorator is defined in a different module and
  uses `functools.wraps()`.
- A class decorator using the `__wrapped__` convention where the wrapped
  original class defines documented `__init__`.
- A nested decorated class member to confirm dotted module+qualname resolution.
- A top-level direct-call compatibility case where module lookup is unavailable
  but `obj.__globals__[cls_path]` works.
- Negative cases for disabled config and non-owner members.

No test should be removed based on this proof unless the emitted K commands are
run successfully and return `#Top`. Even then, integration tests for real Python
object behavior should remain because PO10 is outside the mini model.

## Commands For Later Machine Check

These commands were not run:

```sh
kompile fvk/mini-napoleon.k --backend haskell
kast --backend haskell fvk/napoleon-skip-member-spec.k
kprove fvk/napoleon-skip-member-spec.k
```

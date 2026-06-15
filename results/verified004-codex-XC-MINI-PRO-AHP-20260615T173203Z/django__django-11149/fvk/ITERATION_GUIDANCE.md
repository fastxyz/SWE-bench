# ITERATION_GUIDANCE

## Verdict

V1 stands unchanged.

The FVK audit found that the reported issue is discharged by the V1 code: target model `view` permission still grants read access, but target model `change` permission is required for every add/change/delete hook on auto-created many-to-many intermediary inlines.

## Why No Code Change Was Applied

- F1 and PO2 show that V1 fixes the pre-V1 bug where view permission implied write permission.
- PO3 and PO4 show that once the write hooks return false, the rendering and POST paths treat the inline as read-only and preserve the original relationship state.
- PO5 shows that V1 preserves the existing public behavior where target `change` enables m2m relationship inline editing.
- PO6 shows no public hook signature changed.

## Rejected Next Edits

1. Require target `add` for relationship additions and target `delete` for relationship removals.
   - Rejected by F2 and PO5. A relationship row write is established public behavior under target `change`, and add/delete of the target object are different operations.

2. Hide auto-created m2m inlines from target-view-only users.
   - Rejected by F3 and PO1. The issue requires preventing edits, not preventing read-only display.

3. Add a parent model `change` requirement.
   - Rejected by F4 and PO6 for this issue. It is a broader behavior change to inline edit semantics and is not required to block the reported view-only user.

## Recommended Tests For Maintainers

Do not edit tests in this task. If maintainers add coverage later, the most direct regression test is:

- A user with only view permissions for parent and target can open the parent change view, sees the auto-created m2m inline read-only, and a POST attempting to add/remove through rows leaves the relation unchanged.

Useful matrix cases:

- target view only: inline visible, no writes accepted;
- target change: writes accepted;
- target add only: no relationship writes accepted;
- explicit through model: unchanged behavior under its own model permissions.

## Machine Checking

When K is available, run:

```sh
kompile fvk/mini-admin-permissions.k --backend haskell
kast --backend haskell fvk/admin-inline-permissions-spec.k
kprove fvk/admin-inline-permissions-spec.k
```

Until then, keep all tests. The proof is constructed, not machine-checked.

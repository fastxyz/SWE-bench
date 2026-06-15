# FVK Iteration Guidance

Status: V1 is confirmed for the public issue domain; no additional production
code change is justified by the FVK audit.

## Code Guidance

Keep V1 unchanged:

- The dependency generation in `generate_created_models()` satisfies PO-001.
- Existing `check_dependency()` satisfies PO-002, so changing it would be
  unnecessary.
- Existing same-app sorting and cross-app migration splitting satisfy PO-003
  and PO-004.
- `generate_removed_fields()` still owns `RemoveField` generation, satisfying
  PO-005 and the multiple-subclass public hint.
- No public API or prompt behavior change is required, satisfying PO-007.

Do not broaden the fix to add warnings or prompts unless a separate public
requirement asks for that behavior. The issue intent supports operation
ordering; data-loss UX remains underspecified.

## Suggested Tests for a Future Test-Allowed Pass

Do not edit tests in this benchmark. If test edits were allowed later, add
autodetector tests for:

1. Direct case: old `Readable.title`, new `Readable` without `title`, new
   `Book(Readable)` with local `title`; assert `RemoveField` precedes
   `CreateModel`.
2. Multiple subclasses: add `Book` and `Magazine` with local `title`; assert one
   `RemoveField` and both creates after it.
3. Related-field variant: move a relation field from base to new subclass;
   assert `RemoveField` precedes `CreateModel` and deferred `AddField`.
4. Optional cross-app variant: base in one app, subclass in another; assert the
   child migration depends on the base migration.

## Verification Guidance

The proof is constructed only. In an environment with K available, use the
abstract `.k` files named in `fvk/PROOF.md` and run the recorded commands. In
a Django execution environment, run the focused migration autodetector tests
and the existing migration test module. Neither action is permitted in this
benchmark session.

## Next-Iteration Questions

No blocking intent question remains for this issue. A separate product question
could ask whether data-loss warnings should be added when moving a field from a
base model to subclasses, but that is outside this fix.

# PROOF

Status: constructed, not machine-checked. No tests, Python code, `kompile`, `kast`, or `kprove` were run.

## What is proved

Under the success-path precondition that the form is valid and the delegated Django operations return normally:

- `save(commit=True)` with pending many-to-many form data hashes the password, saves the user, saves the m2m data after the user save, and returns the user.
- `save(commit=False)` hashes the password, returns the unsaved user, and leaves m2m data pending for the deferred hook.
- `save(commit=True)` with no m2m data preserves the existing user/password behavior and has no related data to persist.

The proof is over the mini semantics in `mini-django-usercreationform.k` and the claims in `usercreationform-save-spec.k`.

## Symbolic proof sketch

### C-COMMIT-TRUE-M2M

Initial state: `commit = true`, `valid = true`, `hasM2M = true`, `m2m = noM2M`, `password = rawPassword`, `userSaved = false`, `result = noReturn`.

1. Sequence rule exposes `super_save_false`.
2. `super_save_false` rule applies because `valid = true` and `hasM2M = true`; it changes `m2m` to `pendingM2M` and records `superSaveFalse`.
3. `set_password` rule changes `password` to `hashedPassword` and records `setPassword`.
4. `if_commit_save` sees `commit = true` and rewrites to `user_save ; save_m2m ; return_user`.
5. `user_save` changes `userSaved` to `true` and records `userSave`.
6. `save_m2m` is enabled because `userSaved = true` and `m2m = pendingM2M`; it changes `m2m` to `savedM2M` and records `saveM2M`.
7. `return_user` writes `result = user` and records `returnUser`.

The final state matches the claim: hashed password, saved user, saved m2m data, returned user, and the required event order. The key verification condition is the enablement of `save_m2m`; it is discharged by step 5.

### C-COMMIT-FALSE-M2M

Initial state is the same except `commit = false`.

1. `super_save_false` creates pending m2m state.
2. `set_password` hashes the password.
3. `if_commit_save` sees `commit = false` and rewrites directly to `return_user`.
4. `return_user` returns the user.

No `user_save` or `save_m2m` transition occurs. The final state has `m2m = pendingM2M`, `userSaved = false`, `password = hashedPassword`, and `result = user`, matching the deferred-save claim.

### C-COMMIT-TRUE-NO-M2M

Initial state has `commit = true` and `hasM2M = false`.

1. `super_save_false` records the superclass save but leaves `m2m = noM2M`.
2. `set_password` hashes the password.
3. `if_commit_save` takes the committed branch.
4. `user_save` sets `userSaved = true`.
5. `save_m2m` is enabled in the `noM2M` state and leaves it unchanged.
6. `return_user` returns the user.

The added committed-path call is therefore harmless for forms without m2m data.

## V0 discriminator

If the committed branch were modeled as `user_save ; return_user` with no `save_m2m`, the `C-COMMIT-TRUE-M2M` post-state would be unreachable: after `return_user`, `m2m` would still be `pendingM2M`, not `savedM2M`, and the event list would lack `saveM2M`. This separates the pre-fix bug from V1 in the formal observable.

## Loops and circularities

No loop or recursion occurs in the modeled method. Therefore no circularity claim is required.

## Residual risk

- The proof is constructed but not machine-checked.
- The mini semantics abstracts Django's database layer and `ModelForm._save_m2m()` internals to their documented effects.
- Termination of external database operations is not proved; the method-level control flow itself is finite if delegated operations return.
- Test removal is not recommended without machine-checking.

## Commands to run later

From the workspace root, in an environment with K installed:

```sh
cd fvk
kompile mini-django-usercreationform.k --backend haskell
kast --backend haskell usercreationform-save-spec.k
kprove usercreationform-save-spec.k
```

Expected machine-check result after those commands: `kprove` discharges all three claims and returns `#Top`.

## Test guidance

Do not delete tests based on this constructed proof. After machine-checking, a focused unit test asserting that a committed custom `UserCreationForm` saves many-to-many data would be subsumed by `C-COMMIT-TRUE-M2M`, but integration, admin, invalid-form, and `commit=False` tests should be kept because they cover behavior outside or around the modeled unit.

# PROOF OBLIGATIONS

Status: constructed, not machine-checked.

## PO-001: Committed save persists m2m form data

- Claim: For a valid `UserCreationForm` with `commit=True` and included many-to-many form data, `save()` must return only after that related data has been saved.
- Evidence: E-001, E-002, E-003.
- Formal claim: `C-COMMIT-TRUE-M2M`.
- Finding trace: F-001.
- V1 discharge: `self.save_m2m()` executes inside the committed branch after `user.save()`.

## PO-002: m2m persistence is ordered after instance persistence

- Claim: The committed path must call the m2m save hook after the user instance has been saved.
- Evidence: E-003, E-004.
- Formal claim: event order in `C-COMMIT-TRUE-M2M`.
- Finding trace: F-002.
- V1 discharge: source order is `user.save()` then `self.save_m2m()`.

## PO-003: Password hashing and return value are preserved

- Claim: `save()` must set the password using `set_password()` and return the user instance.
- Evidence: E-002 and existing auth form source.
- Formal claims: all three claims.
- Finding trace: F-001.
- V1 discharge: V1 leaves `user.set_password(...)` before the commit branch and `return user` after it.

## PO-004: `commit=False` remains deferred

- Claim: On `commit=False`, the method must not save the user or m2m data; it must leave the m2m hook available through the superclass deferred path.
- Evidence: E-003, E-004, E-007.
- Formal claim: `C-COMMIT-FALSE-M2M`.
- Finding trace: F-003.
- V1 discharge: the added `self.save_m2m()` call is guarded by `if commit:`.

## PO-005: No-m2m committed saves remain harmless

- Claim: For valid committed forms with no included m2m fields, the added hook call must not change the observable user/password result.
- Evidence: E-002, E-003.
- Formal claim: `C-COMMIT-TRUE-NO-M2M`.
- Finding trace: F-004.
- V1 discharge: `save_m2m()` delegates to ModelForm's m2m saver; with no matching fields, there is no related data to write.

## PO-006: Invalid form behavior is not redefined

- Claim: Saving invalid forms remains delegated to `ModelForm.save()` error behavior.
- Evidence: `BaseModelForm.save()` raises before commit handling when `self.errors` is present.
- Formal treatment: success-path precondition `valid = true`; invalid input is outside this proof's domain.
- Finding trace: none as source bug; recorded in `SPEC.md` as a domain condition.
- V1 discharge: V1 still calls `super().save(commit=False)` before auth-specific mutations.

## PO-007: Public compatibility is preserved

- Claim: The source change must not alter method signature, return shape, subclass contract, or admin `commit=False` flow.
- Evidence: E-005, E-007.
- Formal treatment: compatibility audit plus `C-COMMIT-FALSE-M2M`.
- Finding trace: F-004.
- V1 discharge: no signature change; no new arguments; commit-false branch remains deferred.

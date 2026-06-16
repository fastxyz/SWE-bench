# FINDINGS

Status: constructed FVK findings for V1. No hidden tests, evaluator data, or original upstream fix were used.

## F-001: Pre-fix committed save omitted m2m persistence

- Classification: code bug fixed by V1.
- Input: a valid subclass of `UserCreationForm` for a custom user model whose `Meta.fields` includes a `ManyToManyField`, submitted with selected related objects, then saved using `form.save()` / `save(commit=True)`.
- Observed before V1: the user was saved with a hashed password, but related form data remained unsaved because `UserCreationForm.save()` called `super().save(commit=False)` and `user.save()` without a later `save_m2m()`.
- Expected: default committed `ModelForm.save()` behavior saves all data, including m2m data, without requiring the caller to call `save_m2m()`.
- Evidence: E-001, E-002, E-003.
- Proof obligations: PO-001, PO-002, PO-003.
- V1 status: resolved by `repo/django/contrib/auth/forms.py` calling `self.save_m2m()` immediately after `user.save()`.

## F-002: m2m save must occur after user save

- Classification: ordering obligation.
- Input: any valid committed user creation form with pending m2m data.
- Risk: calling m2m saving before the user instance exists would violate the documented ModelForm constraint that m2m data cannot be saved until the instance exists in the database.
- Expected: `user.save()` precedes `save_m2m()`.
- Evidence: E-003, E-004.
- Proof obligations: PO-002.
- V1 status: satisfied; line order is `user.save()` followed by `self.save_m2m()`.

## F-003: `commit=False` must remain deferred

- Classification: frame condition.
- Input: valid custom `UserCreationForm` with pending m2m data saved using `save(commit=False)`.
- Expected: the method returns a user with a hashed password, does not save the user or m2m data, and leaves the `save_m2m()` hook available for the caller after manual user save.
- Evidence: E-003, E-004, E-007.
- Proof obligations: PO-004.
- V1 status: satisfied; the added call is inside `if commit:`.

## F-004: Public API and admin compatibility are preserved

- Classification: compatibility finding.
- Input: public callers and subclasses using `UserCreationForm.save(self, commit=True)`, plus Django admin's `commit=False` save flow.
- Expected: no signature change, same returned user instance, and no changed deferred-save protocol.
- Evidence: E-005, E-007.
- Proof obligations: PO-007.
- V1 status: satisfied; no extra arguments or public method shape changes were introduced.

## F-005: Proof is constructed, not machine-checked

- Classification: proof capability / environment boundary.
- Input: the FVK K artifacts in this workspace.
- Observed: this task forbids running Python, tests, or K tooling; therefore no `kompile` or `kprove` result exists.
- Expected next step in an execution-capable environment: run the commands listed in `PROOF.md` and expect `kprove` to return `#Top` for the three claims.
- Evidence: task constraints and FVK honesty gate.
- Proof obligations: all.
- V1 status: not a source bug. Test deletion is not recommended unless the K proof is machine-checked.

## Proof-derived findings from `/verify`

No additional code defect surfaced during the constructed proof. The only proof side conditions are already public-intent obligations: valid form input, normal return from external database/hook operations, and the required ordering of user save before m2m save.

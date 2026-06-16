# SPEC

Status: FVK formalization for `django.contrib.auth.forms.UserCreationForm.save()`. Constructed, not machine-checked.

## Scope

The audited unit is `repo/django/contrib/auth/forms.py`, method `UserCreationForm.save(self, commit=True)`.

The relevant V1 source sequence is:

1. `user = super().save(commit=False)`
2. `user.set_password(self.cleaned_data["password1"])`
3. if `commit`: `user.save()`
4. if `commit`: `self.save_m2m()`
5. `return user`

The model abstracts Django internals to the state changed by this issue: whether the password has been hashed, whether the user has been saved, whether m2m form data is pending or saved, the returned object, and the ordering of save events. It does not model database engine failures or invalid-form exceptions.

## Public Intent Ledger

Critical ledger entries are mirrored in `PUBLIC_EVIDENCE_LEDGER.md` and in `SPEC-PROVENANCE` comments above the K claims.

| ID | Source | Evidence | Semantic obligation | Status |
| --- | --- | --- | --- | --- |
| E-001 | prompt | `UserCreationForm` should save data from ManyToMany form fields; omission is failure to call `self.save_m2m()`. | committed save persists related form data | encoded by `C-COMMIT-TRUE-M2M` |
| E-002 | docs | `UserCreationForm` is a `ModelForm` for creating a new user and sets the password with `set_password()`. | preserve ModelForm save contract and password hashing | encoded by all claims |
| E-003 | docs | `ModelForm.save(commit=False)` defers m2m because instance must exist first; normal `save()` saves all data including m2m. | `user.save()` before `save_m2m()` on commit; defer on `commit=False` | encoded by `C-COMMIT-TRUE-M2M` and `C-COMMIT-FALSE-M2M` |
| E-004 | source | `BaseModelForm.save()` saves instance then `_save_m2m()` for commit, or installs `save_m2m` for noncommit. | implementation evidence for the transition shape | encoded by rules `super_save_false` and `save_m2m` |
| E-005 | docs/tests | Custom user forms extend `UserCreationForm.Meta` with additional fields. | custom m2m fields are in scope | encoded by `hasM2M = true` claims |
| E-006 | source | V1 calls `self.save_m2m()` after `user.save()`. | candidate behavior to verify | checked by proof obligations |
| E-007 | source | Admin uses `commit=False` then later calls `form.save_m2m()`. | preserve deferred path and public API shape | checked by compatibility audit |

## Formal Artifacts

- `mini-django-usercreationform.k`: minimal K semantics for the audited method sequence.
- `usercreationform-save-spec.k`: K reachability claims.
- `FORMAL_SPEC_ENGLISH.md`: English paraphrase of each claim.
- `SPEC_AUDIT.md`: adequacy gate comparing formal claims to public intent.
- `PUBLIC_COMPATIBILITY_AUDIT.md`: signature/callsite/subclass compatibility.

## Claims

### C-COMMIT-TRUE-M2M

Precondition: valid form, `commit=True`, and included m2m form data is pending after `super().save(commit=False)`.

Postcondition: password is hashed, user is saved, m2m data is saved, returned object is the user, and the order is `superSaveFalse -> setPassword -> userSave -> saveM2M -> returnUser`.

### C-COMMIT-FALSE-M2M

Precondition: valid form, `commit=False`, and included m2m form data exists.

Postcondition: password is hashed, user is returned unsaved, m2m data remains pending for the deferred `save_m2m()` hook, and no `userSave` or `saveM2M` event occurs.

### C-COMMIT-TRUE-NO-M2M

Precondition: valid form, `commit=True`, and no included m2m form data exists.

Postcondition: password is hashed, user is saved and returned, and the m2m state remains empty. The `saveM2M` transition is harmless in this state.

## Domain and Frame Conditions

- Valid-form success path only. Invalid-form behavior is delegated to `ModelForm.save()` and remains unchanged.
- Database and relation-save operations are assumed to return normally; external I/O failures are outside this proof.
- Public method signature and return shape are unchanged.
- No loop or recursion exists in the modeled method, so no circularity claim is needed.

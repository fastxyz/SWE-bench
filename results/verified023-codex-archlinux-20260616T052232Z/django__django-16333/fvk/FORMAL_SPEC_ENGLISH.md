# Formal Spec in English

This file paraphrases the nontrivial claims in `usercreationform-save-spec.k`.

## C-COMMIT-TRUE-M2M

For any valid `UserCreationForm` save operation with `commit=True` and pending many-to-many form data, execution of the V1 method sequence:

1. delegates to `ModelForm.save(commit=False)`, which creates the user instance and installs the deferred m2m save hook;
2. hashes the password with `set_password()`;
3. saves the user instance;
4. invokes `save_m2m()` after the user save;
5. returns the user.

The post-state has a saved user, a hashed password, saved m2m data, and the returned value is the user. The event order is `superSaveFalse`, `setPassword`, `userSave`, `saveM2M`, `returnUser`.

## C-COMMIT-FALSE-M2M

For any valid `UserCreationForm` save operation with `commit=False` and pending many-to-many form data, execution delegates to `ModelForm.save(commit=False)`, hashes the password, and returns the user without saving the user or the m2m data. The m2m state remains pending for a later caller-invoked `save_m2m()`.

## C-COMMIT-TRUE-NO-M2M

For a valid committed save with no many-to-many form data, execution still delegates through the same committed path and calls `save_m2m()`, but the m2m state remains empty. The user is saved, the password is hashed, and the user is returned.

## Side Conditions

S-001. The modeled success-path domain assumes a valid form. Invalid-form error behavior is inherited from `ModelForm.save()` before the auth-specific save sequence and is recorded as a precondition, not as a postcondition.

S-002. The proof is partial with respect to external database and hook operations: if `super().save(commit=False)`, `user.save()`, and `save_m2m()` return normally, the method sequence reaches the post-state. Database failures and validation failures are outside the modeled success path.

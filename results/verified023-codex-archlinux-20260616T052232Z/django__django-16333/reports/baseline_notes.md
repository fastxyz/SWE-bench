# Baseline Notes

## Root cause

`django.contrib.auth.forms.UserCreationForm.save()` overrides `ModelForm.save()` so it can hash `password1` before saving the user. The override calls `super().save(commit=False)`, which prepares `save_m2m()` for deferred many-to-many saving, but when `commit=True` it only calls `user.save()`. Unlike `ModelForm.save(commit=True)`, it did not call `save_m2m()`, so many-to-many form fields included by custom user creation forms were never persisted.

## Changed files

`repo/django/contrib/auth/forms.py`

Added `self.save_m2m()` immediately after `user.save()` in `UserCreationForm.save(commit=True)`. This keeps the existing password hashing flow and commit behavior while restoring the standard `ModelForm` behavior of saving many-to-many and related form data after the instance has a primary key.

## Assumptions and alternatives considered

I assumed the intended contract is to match `ModelForm.save(commit=True)`: save the instance first, then save many-to-many form data. This is necessary because many-to-many data cannot be saved until the user instance has been written.

I considered calling `_save_m2m()` directly, mirroring `BaseModelForm.save(commit=True)`, but `UserCreationForm.save()` already obtains the instance through `super().save(commit=False)`, which installs `save_m2m()` as the public deferred hook. Calling `self.save_m2m()` is the smallest change and matches the issue description.

I considered changing the `commit=False` path, but that path already inherits the deferred `save_m2m()` behavior from `ModelForm.save(commit=False)`. The bug is limited to the committed path.

I considered applying similar changes to password change/reset forms, but those forms are not `ModelForm` subclasses saving model form many-to-many fields; they update an existing user password and do not have the same `save_m2m()` contract.

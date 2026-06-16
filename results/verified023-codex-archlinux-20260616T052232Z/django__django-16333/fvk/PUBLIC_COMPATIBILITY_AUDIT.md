# Public Compatibility Audit

Changed symbol: `django.contrib.auth.forms.UserCreationForm.save(self, commit=True)`.

## Signature and return shape

- Status: pass.
- The method signature remains `save(self, commit=True)`.
- The return value remains the user instance.
- No new caller arguments, keyword arguments, or return wrapper were introduced.

## Public callsites

- `django.contrib.auth.admin.UserAdmin.add_form` continues to point to `UserCreationForm`.
- Normal admin model saving calls `form.save(commit=False)` and later `form.save_m2m()` through `ModelAdmin.save_related()`. V1 does not call `save_m2m()` on the `commit=False` branch, so this flow remains compatible.
- Direct callers of `form.save()` on a valid custom user creation form now receive the documented `ModelForm.save()` behavior: the instance and m2m data are saved on the committed path.

## Subclass and override compatibility

- Existing subclasses that inherit `UserCreationForm.save()` get the fixed behavior without changing their code.
- Subclasses that override `save()` entirely are unaffected by this source change.
- The internal call is `self.save_m2m()` with no new arguments. That method is installed by `super().save(commit=False)` according to `ModelForm.save(commit=False)`, so the call does not introduce a new public override signature.

## Compatibility verdict

Pass. The V1 source change alters only the missing committed-path side effect required by the public `ModelForm` contract. It does not change the public API shape or the deferred save protocol.

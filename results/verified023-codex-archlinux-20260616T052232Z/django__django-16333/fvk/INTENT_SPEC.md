# Intent Spec

Status: constructed from public issue text, Django source, and in-repo public docs. The current V1 implementation is treated as candidate behavior, not as intent by itself.

## Required behavior

I-001. `UserCreationForm` is a `ModelForm` for creating a user, so its default `save(commit=True)` behavior must preserve the ordinary `ModelForm.save()` contract unless the auth form documents a narrower exception.

I-002. For a valid custom `UserCreationForm` whose `Meta.fields` include model many-to-many or generic relation form fields, `save(commit=True)` must save the user instance and the related form data before returning. Callers must not need an additional `form.save_m2m()` call on the default committed path.

I-003. Many-to-many form data must be saved only after the user instance exists in the database. Therefore, the committed path must order `user.save()` before `save_m2m()`.

I-004. `save(commit=False)` must keep the usual deferred-save behavior: return an unsaved user instance with the password set, leave related data pending, and leave a callable `save_m2m()` hook for the caller to invoke after saving the instance manually.

I-005. `UserCreationForm.save()` must continue to set the password with `set_password()` and return the user instance.

I-006. Invalid form behavior is inherited from `ModelForm.save()`: saving an invalid form is outside the verified success-path domain and raises through the superclass before auth-specific saving occurs.

I-007. Public compatibility must be preserved: the method signature stays `save(self, commit=True)`, no new caller arguments are required, and public admin/subclass usage remains compatible.

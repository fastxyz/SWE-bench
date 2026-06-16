# Public Evidence Ledger

## E-001: Issue statement

- Source: prompt.
- Evidence: "UserCreationForm should save data from ManyToMany form fields" and "unlike its parent class django.forms.ModelForm, UserCreationForm.save(commit=True) omits to call self.save_m2m()."
- Obligation: `UserCreationForm.save(commit=True)` must save related many-to-many form data for custom user forms.
- Status: encoded by `C-COMMIT-TRUE-M2M` in `usercreationform-save-spec.k`; addressed by `PO-001`.

## E-002: UserCreationForm public docs

- Source: docs.
- Evidence: `docs/topics/auth/default.txt` describes `UserCreationForm` as "A ModelForm for creating a new user" and says it sets the password with `set_password()`.
- Obligation: preserve both the `ModelForm` save contract and password hashing behavior.
- Status: encoded by `I-001`, `I-005`, `PO-001`, and `PO-003`.

## E-003: ModelForm save_m2m docs

- Source: docs.
- Evidence: `docs/topics/forms/modelforms.txt` says `save(commit=False)` adds `save_m2m()` because many-to-many data cannot be saved until the instance exists in the database; it also says normal `save()` saves all data, including many-to-many data, without additional calls.
- Obligation: committed save must persist m2m data after the instance save; uncommitted save must defer m2m data.
- Status: encoded by `I-002`, `I-003`, `I-004`, `PO-001`, `PO-002`, and `PO-004`.

## E-004: BaseModelForm implementation

- Source: source code.
- Evidence: `django/forms/models.py` saves the instance then `_save_m2m()` for `commit=True`, and installs `save_m2m = _save_m2m` for `commit=False`.
- Obligation: use the superclass behavior as implementation evidence for ordering and deferred hook availability.
- Status: encoded by `PO-002` and `PO-004`; not used as the sole source of user-facing intent.

## E-005: Custom user extension docs and public tests

- Source: docs and public tests.
- Evidence: `docs/topics/auth/customizing.txt` shows `UserCreationForm` being extended for custom user fields; public auth form tests define custom `UserCreationForm.Meta` classes with extra fields.
- Obligation: the save contract must work for custom subclasses that add model fields, including many-to-many fields described by the issue.
- Status: encoded by `PO-001` and `PO-007`.

## E-006: UserCreationForm V1 source

- Source: implementation.
- Evidence: `repo/django/contrib/auth/forms.py` now calls `super().save(commit=False)`, `user.set_password(...)`, `user.save()`, `self.save_m2m()`, and returns `user`.
- Obligation: this is the candidate transition sequence to audit, not independent intent.
- Status: modeled in `mini-django-usercreationform.k` and checked by `C-COMMIT-TRUE-M2M`, `C-COMMIT-FALSE-M2M`, and `C-COMMIT-TRUE-NO-M2M`.

## E-007: Admin callsites

- Source: source code.
- Evidence: `django/contrib/admin/options.py` uses `form.save(commit=False)` during normal admin object saving and later calls `form.save_m2m()` in `save_related()`. `django/contrib/auth/admin.py` exposes `UserCreationForm` as `add_form`.
- Obligation: the V1 fix must not require changed admin call signatures or break the deferred `commit=False` path.
- Status: encoded by `PUBLIC_COMPATIBILITY_AUDIT.md` and `PO-004`/`PO-007`.

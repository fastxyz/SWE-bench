# FVK Notes

## Decision summary

The FVK audit confirms V1 and leaves `repo/django/contrib/auth/forms.py` unchanged. The added `self.save_m2m()` call is necessary and sufficient for the reported committed-save bug under the public intent captured in `fvk/SPEC.md`.

## Decisions traced to findings and proof obligations

1. Kept the V1 source line `self.save_m2m()` after `user.save()`.
   - Trace: `F-001`, `F-002`, `PO-001`, `PO-002`.
   - Reason: the public issue and `ModelForm` docs require committed saves to persist m2m data, and the docs require the instance to exist before m2m data is saved.

2. Did not replace `self.save_m2m()` with `self._save_m2m()`.
   - Trace: `F-003`, `PO-004`.
   - Reason: `UserCreationForm.save()` obtains its instance through `super().save(commit=False)`, which installs the public deferred hook. Calling `self.save_m2m()` matches the public ModelForm contract and the issue text while preserving commit-false behavior.

3. Did not change the `commit=False` branch.
   - Trace: `F-003`, `PO-004`.
   - Reason: the superclass already supplies deferred `save_m2m()` behavior on `commit=False`; V1's new call is guarded by `if commit:`.

4. Did not edit admin, password reset/change forms, or subclass callsites.
   - Trace: `F-004`, `PO-007`.
   - Reason: the changed symbol's signature and return shape are unchanged. Password reset/change forms are not `ModelForm` saves for related form fields, and admin's normal object flow already uses `commit=False` followed by `form.save_m2m()`.

5. Did not edit tests.
   - Trace: `F-005`.
   - Reason: the task forbids modifying test files, and the constructed proof is not machine-checked. `fvk/PROOF.md` records test guidance only.

6. Did not make additional docs/source changes for the standalone custom-auth documentation example.
   - Trace: `F-001`, `PO-001`.
   - Reason: the reported public API defect is in `django.contrib.auth.forms.UserCreationForm.save()`. The separate documentation example shown in `docs/topics/auth/customizing.txt` defines its own local form for concrete non-m2m fields and is not the audited source method.

## Proof status

The proof artifacts are complete under `fvk/`, including the required five task artifacts and the FVK formal/adequacy core. The proof is constructed, not machine-checked, because this session forbids running K tooling, Python, or tests. The commands to machine-check later are recorded in `fvk/PROOF.md`.

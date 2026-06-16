# FVK Notes

## Runtime Fix Decision

I kept the V1 runtime source change in
`repo/django/contrib/auth/forms.py`: `ReadOnlyPasswordHashField.__init__()` now
sets `kwargs.setdefault("disabled", True)`.

This is justified by `fvk/FINDINGS.md` entries F1 and F2. F1 identifies the
pre-V1 custom-form tampering bug, and F2 records that V1 satisfies the intended
field-level contract. The corresponding proof obligations are PO1, PO2, and
PO3 in `fvk/PROOF_OBLIGATIONS.md`: default construction must set
`disabled=True`, disabled-field cleaning must use the initial value, and custom
forms must no longer need a `clean_password()` hook to ignore tampered password
data.

## Documentation Change

I changed `repo/docs/topics/auth/customizing.txt` by removing the obsolete
`clean_password()` method from the custom-user `UserChangeForm` example.

This is justified by F3 in `fvk/FINDINGS.md`, which found that V1 left public
documentation teaching the old workaround. PO6 in `fvk/PROOF_OBLIGATIONS.md`
states the docs obligation: the example must not continue to require
`clean_password()` for `ReadOnlyPasswordHashField` now that the field owns the
disabled behavior.

## Rejected Source Change

I did not remove `UserChangeForm.clean_password()` from
`repo/django/contrib/auth/forms.py`.

This is justified by F4 and PO5. The method is now redundant for correctness,
but keeping it is compatible with the field-level proof because it returns the
same initial password value selected by the disabled-field cleaning path.
Removing it would be an avoidable public-method compatibility change not
required by the issue.

## FVK Artifacts

I added the requested artifacts:

- `fvk/SPEC.md`
- `fvk/FINDINGS.md`
- `fvk/PROOF_OBLIGATIONS.md`
- `fvk/PROOF.md`
- `fvk/ITERATION_GUIDANCE.md`

I also added the formal core required by the FVK docs:

- `fvk/mini-django-forms.k`
- `fvk/readonly-password-hash-field-spec.k`

These artifacts trace the public intent to claims C1-C4, record findings F1-F5,
and list exact `kompile`, `kast`, and `kprove` commands for later use. F5 keeps
the honesty boundary explicit: the proof is constructed, not machine-checked.

## Execution Constraints

I did not run tests, Python, or K tooling. Commands that the FVK method would
normally execute are written into the artifacts only, with expected outcomes
reasoned about from the source and the mini semantics.

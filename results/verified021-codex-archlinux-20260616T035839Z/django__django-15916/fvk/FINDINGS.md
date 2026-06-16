# FINDINGS.md

Status: constructed findings; no tests or K tooling were executed.

## F1: V1 Inherited Base Callback Through Replacement Meta

- Classification: code bug in V1; fixed in V2.
- Evidence: `SPEC.md` entries E3 and E4; `PROOF_OBLIGATIONS.md` PO6.
- Input:

  ```python
  class BaseForm(forms.ModelForm):
      class Meta:
          model = Person
          fields = "__all__"
          formfield_callback = base_callback

  class ChildForm(BaseForm):
      class Meta:
          model = Person
          fields = "__all__"
  ```

- V1 observed by code inspection: `ChildForm` used `base_callback` because V1
  fell back to `base_formfield_callback` when the replacement `Meta` lacked the
  option.
- Expected: `ChildForm.Meta` is the resolved inner `Meta` under normal Python
  name resolution. Since it does not define or inherit `formfield_callback`, no
  callback should be used.
- Change made: removed the special base-form fallback from
  `ModelFormMetaclass.__new__()`. The metaclass now falls back only to
  `opts.formfield_callback` from the resolved `Meta`.

## F2: Factory Default None Masked Meta Callback Before V1

- Classification: reported code bug; fixed in V1 and preserved in V2.
- Evidence: `SPEC.md` entries E1 and E2; `PROOF_OBLIGATIONS.md` PO1 and PO3.
- Input:

  ```python
  FactoryForm = forms.modelform_factory(MyModel, form=MyForm)
  ```

  where `MyForm.Meta.formfield_callback = all_required`.

- Pre-fix observed from source: the factory installed a top-level
  `formfield_callback = None`, and the metaclass used that `None`.
- Expected: omitted factory callback is not an explicit override; the generated
  form uses `MyForm.Meta.formfield_callback`.
- V2 status: fixed by omitting the top-level class attribute when the factory
  argument is `None`.

## F3: Direct Meta Formfield Callback Was Not Read Before V1

- Classification: reported feature/behavior gap; fixed in V1 and preserved in
  V2.
- Evidence: `SPEC.md` entries E2 and E3; `PROOF_OBLIGATIONS.md` PO2.
- Input:

  ```python
  class MyForm(forms.ModelForm):
      class Meta:
          model = MyModel
          fields = "__all__"
          formfield_callback = all_required
  ```

- Pre-fix observed from source: `ModelFormMetaclass` did not read the current
  form's `Meta.formfield_callback` when choosing the callback for
  `fields_for_model()`.
- Expected: the current form's `Meta.formfield_callback` is used like other
  `Meta` options.
- V2 status: fixed by storing the option on `ModelFormOptions` and passing
  `opts.formfield_callback` to `fields_for_model()`.

## F4: Truthiness Was Too Strong For Explicit Factory Callback Detection

- Classification: corner-case bug risk; fixed in V1 and preserved in V2.
- Evidence: `SPEC.md` entry E6; `PROOF_OBLIGATIONS.md` PO5.
- Input: a callable object passed as `formfield_callback` whose `__bool__()`
  returns `False`.
- Pre-fix observed from source: `if formfield_callback:` would not store that
  object on the generated `Meta`, which could break inheritance of the explicit
  callback.
- Expected: any non-`None` object is an explicit factory argument and should be
  preserved for validation or callback use.
- V2 status: fixed by checking `formfield_callback is not None`.

## F5: Constructed Proof Is Not Machine Checked

- Classification: proof honesty / residual verification risk.
- Evidence: FVK docs require labeling MVP proofs "constructed, not
  machine-checked"; task forbids running K tooling.
- Input: all claims in `fvk/modelform-callback-spec.k`.
- Observed: commands are recorded in `PROOF.md` but not run.
- Expected before test deletion or machine-verified confidence: run the emitted
  `kompile` and `kprove` commands and require `#Top`.
- V2 status: no code change required; keep tests until machine-checking is
  possible.

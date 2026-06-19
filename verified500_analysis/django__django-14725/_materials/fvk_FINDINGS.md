# FVK Findings

Status: constructed, not machine-checked. No tests, Python, or K tooling were
run.

## F-1: Original save-time creation path

Classification: code bug addressed by V1 and retained in V2.

Evidence: prompt entries E-1 through E-3 and proof obligations PO-1 through
PO-4.

Input -> observed vs expected:

- Input: a bound model formset intended to be edit-only, with extra submitted
  form data caused by JavaScript or tampered management form counts.
- Observed before the fix: `BaseModelFormSet.save()` could reach
  `save_new_objects()` and create model instances from eligible extra forms.
- Expected: an explicit edit-only mode must allow existing-object saves but
  create zero new model instances.

Resolution: `BaseModelFormSet.save()` now returns only
`save_existing_objects()` when `self.edit_only` is true, and the base
`save_new_objects()` method also returns an empty `new_objects` list under the
same flag.

## F-2: V1 virtual-dispatch gap

Classification: proof-derived code bug in V1; fixed in V2.

Evidence: public compatibility entry C-5 and proof obligation PO-7.

Input -> observed vs expected:

- Input: a formset class created with `edit_only=True` using a custom formset
  subclass that overrides `save_new_objects()` and does not call `super()`.
- Observed in V1 by static dispatch reasoning: `BaseModelFormSet.save()` still
  called `self.save_new_objects(commit)`, so the override could create new
  objects despite edit-only mode.
- Expected: the public `save()` entry point must not dispatch to any
  new-object creation path when edit-only mode is enabled.

Resolution: V2 adds the edit-only guard inside `BaseModelFormSet.save()` before
the virtual call to `save_new_objects()`. The base helper guard remains for
direct calls to the base implementation.

## F-3: Factory propagation is required and satisfied

Classification: confirmed requirement.

Evidence: intent entries I-1, I-5, I-6 and proof obligation PO-6.

Input -> observed vs expected:

- Input: `modelformset_factory(..., edit_only=True)`,
  `inlineformset_factory(..., edit_only=True)`, or
  `generic_inlineformset_factory(..., edit_only=True)`.
- Observed in V2 by static source inspection: the returned formset class gets
  `edit_only=True`; inline and generic inline wrappers pass the keyword to
  `modelformset_factory()`.
- Expected: all public model formset factory paths expose or propagate the
  opt-in mode.

Resolution: V1 already satisfied this; V2 keeps it unchanged.

## F-4: Validation semantics intentionally unchanged

Classification: residual behavior, not a code bug for this issue.

Evidence: intent entries I-2 through I-4 and proof obligations PO-2, PO-3, and
PO-5.

Input -> observed vs expected:

- Input: edit-only formset bound with changed extra-form data that fails normal
  form validation.
- Observed in V2 by static source inspection: edit-only mode prevents
  save-time creation, but it does not silently ignore or remove extra forms
  during validation.
- Expected for this issue: "disallow new object creation"; the public evidence
  does not require changing form validation or management-form semantics.

Resolution: no validation changes were made. This avoids broad behavior changes
outside the save-time creation requirement.

## F-5: Normal creation behavior remains available

Classification: confirmed frame condition.

Evidence: intent entry I-4 and proof obligations PO-4 and PO-5.

Input -> observed vs expected:

- Input: model formset with `edit_only=False` and eligible changed extra forms.
- Observed in V2 by static source inspection: `save()` still returns
  `save_existing_objects(commit) + save_new_objects(commit)`.
- Expected: default model formsets continue to support adding new objects.

Resolution: no further code change needed.

## F-6: Constructed proof not machine-checked

Classification: proof capability / environment gap.

Evidence: benchmark no-exec rule and proof obligation PO-9.

Input -> observed vs expected:

- Input: the emitted K commands in `PROOF.md`.
- Observed in this environment: commands were not executed.
- Expected: artifacts must be labeled "constructed, not machine-checked"; test
  removal must not be recommended unless a later `kprove` run returns `#Top`.

Resolution: the proof and notes carry the required caveat, and no test removal
is recommended.

## F-7: Full `save()` overrides remain outside the base guarantee

Classification: residual compatibility boundary.

Evidence: public compatibility entry C-6 and proof obligation PO-7.

Input -> observed vs expected:

- Input: a subclass that overrides `save()` itself and ignores the base
  implementation.
- Observed by Python dispatch semantics: the subclass can bypass all base-class
  save logic, including `edit_only`.
- Expected: Django's base class can guarantee behavior for the base `save()`
  method and factory-produced classes that use it; it cannot force arbitrary
  full overrides to preserve the new contract.

Resolution: no code change. This is a normal subclassing boundary, not a gap in
the base implementation.

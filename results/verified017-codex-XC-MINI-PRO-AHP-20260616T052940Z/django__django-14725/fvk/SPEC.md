# FVK Specification: django__django-14725

Status: constructed, not machine-checked. No tests, Python, or K tooling were
run.

This benchmark requested five primary FVK markdown artifacts. The adequacy
sections required by the FVK method are consolidated here; the formal core is
also emitted as `fvk/mini-model-formset.k` and `fvk/model-formset-spec.k`.

## Scope

Target production code:

- `repo/django/forms/models.py`
  - `BaseModelFormSet.save()`
  - `BaseModelFormSet.save_new_objects()`
  - `modelformset_factory()`
  - `inlineformset_factory()`
- `repo/django/contrib/contenttypes/forms.py`
  - `generic_inlineformset_factory()`

The audited observable is whether a model formset configured for edit-only use
can create new model instances through the formset save path. Validation details,
database persistence, and model field conversion are abstracted away except for
their contribution to the count of eligible new extra forms.

## Intent Spec

I-1. A caller must have an explicit opt-in way to configure a model formset as
edit-only.

I-2. When that opt-in mode is enabled, calling the formset save path must not
create new model instances, even if POST/management-form data includes extra
submitted forms or tampered `INITIAL_FORMS`/`TOTAL_FORMS` values.

I-3. Edit-only mode must still allow existing objects in the queryset to be
saved or deleted through the existing-object path.

I-4. Normal model formset behavior must be preserved when edit-only mode is not
enabled: changed, non-deleted extra forms remain eligible for creation.

I-5. The public constructor/factory path must carry the opt-in flag onto the
returned formset class.

I-6. Inline and generic inline model formsets are model formset wrappers and
should expose/propagate the same opt-in flag.

I-7. Existing public callsites must remain compatible. Adding a keyword must not
break existing positional or keyword calls, and the edit-only guard must not
depend on un-audited virtual dispatch when a public customization point exists.

## Public Evidence Ledger

E-1. Source: prompt. Quote: "Provide a way for model formsets to disallow new
object creation." Obligation: I-1 and I-2. Status: encoded by `edit_only` and
the `save(true, E, N)` claim.

E-2. Source: prompt. Quote: "extra=0 ... isn't reliable as extra is merely meant
for the extra number of forms to display. You can add more forms with Javascript
(or just send additional post data)." Obligation: the guard must be save-time,
not display-count-only. Status: encoded by quantifying over every `N >= 0`
eligible new form count in the edit-only save claim.

E-3. Source: prompt. Quote: "an extra instance is created if the user edits the
'form-INITIAL_FORMS' form value." Obligation: tampered management form counts
must not let submitted data reach a creation path in edit-only mode. Status:
encoded by the no-creation postcondition for all `N`.

E-4. Source: prompt/hint. Quote: "try to make an edit_only mode for the
ModelFormSet." Obligation: opt-in API name and behavior. Status: encoded by the
`edit_only` class flag and factory keyword.

E-5. Source: implementation. `BaseModelFormSet.save()` saves existing objects
and normally appends `save_new_objects()`. Obligation: the proof model must
represent both existing saves and new saves. Status: modeled as
`save(editOnly, existingSaved, eligibleNew)`.

E-6. Source: implementation. `BaseModelFormSet.save_new_objects()` is the base
loop over changed, non-deleted extra forms that calls `save_new()`. Obligation:
direct base calls must also honor edit-only mode. Status: encoded by
`saveNewObjects(true, N)`.

E-7. Source: implementation/public API. `modelformset_factory()` accepts a
custom `formset` class, and `save()` dispatches methods on `self`. Obligation:
the primary edit-only guard belongs in `save()` before virtual dispatch to
`save_new_objects()`. Status: V2 code change; see Finding F-2 and PO-7.

## Formal Model

The K model abstracts the formset save path to three symbolic values:

- `editOnly: Bool` is the class/instance edit-only flag.
- `E: Int` is the number of existing objects saved/deleted by the existing path.
- `N: Int` is the number of changed, non-deleted extra forms that would create
  new objects if creation were enabled.

Precondition: `E >= 0 and N >= 0`.

Claims in `model-formset-spec.k`:

K-1. `save(true, E, N)` terminates with `result = E`, `created = 0`, and
`newObjects = 0`.

K-2. `save(false, E, N)` terminates with `result = E + N`, `created = N`, and
`newObjects = N`.

K-3. `saveNewObjects(true, N)` terminates with `result = 0`, `created = 0`, and
`newObjects = 0`.

K-4. `saveNewObjects(false, N)` terminates with `result = N`, `created = N`,
and `newObjects = N`.

K-5. `factory(B)` terminates with `editOnly = B`.

Discriminator check: a failing candidate where `save(true, E, N)` reaches
`created = N` for `N > 0` is distinguishable from the required model because
the `created` and `newObjects` cells differ.

## Formal Spec English

K-1 means: for every valid count of existing saves and potential new extra-form
objects, an edit-only formset save returns only the existing-object saves and
creates no new objects.

K-2 means: without edit-only mode, the ordinary save path remains additive over
existing saves plus eligible new extra-form saves.

K-3 means: a direct call to the base `save_new_objects()` implementation is a
no-op for creation when edit-only mode is enabled, and it initializes
`new_objects` to empty.

K-4 means: without edit-only mode, the base `save_new_objects()` path preserves
the existing behavior of saving all eligible extra forms.

K-5 means: public factories transfer the caller's `edit_only` value onto the
formset class they return.

## Spec Audit

K-1 passes against I-1, I-2, and I-3. It is stronger than the issue's concrete
tampered `INITIAL_FORMS` example because it covers every eligible-new-form count
`N`, which is required by the "send additional post data" evidence.

K-2 passes against I-4. It preserves the default behavior only when edit-only is
false.

K-3 passes against I-2 and E-6. It covers the base helper path without making it
the only enforcement point.

K-4 passes against I-4. It is not used to justify edit-only behavior.

K-5 passes against I-1, I-5, and I-6. The concrete source has one direct factory
assignment and two wrapper propagations.

No formal claim relies on legacy behavior described as buggy by the issue.

## Public Compatibility Audit

C-1. `modelformset_factory(..., edit_only=False)` adds an optional parameter at
the end of the existing signature. Existing positional calls keep their argument
meaning, and existing keyword calls are unaffected.

C-2. `inlineformset_factory(..., edit_only=False)` adds the same optional
parameter at the end and passes it through to `modelformset_factory()`.

C-3. `generic_inlineformset_factory(..., edit_only=False)` adds the same
optional parameter at the end and passes it through to `modelformset_factory()`.

C-4. Source callsites found in `django/contrib/admin/options.py` and
`django/contrib/contenttypes/admin.py` pass no positional argument after the
old tail position, so they remain compatible.

C-5. The `formset=` customization point can supply subclasses. V1 guarded the
base `save_new_objects()` method only; V2 guards `BaseModelFormSet.save()`
before virtual dispatch to `save_new_objects()`, so ordinary custom
`save_new_objects()` overrides cannot bypass edit-only mode through `save()`.

C-6. A subclass that overrides `save()` entirely can still ignore `edit_only`;
that is normal Python override behavior and is outside the guarantee of the
base `save()` implementation.

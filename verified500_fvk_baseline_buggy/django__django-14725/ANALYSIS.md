# django__django-14725 — FVK analysis

- **Verdict:** A_GENUINE_FIX — baseline put the `edit_only` guard *only* in the semi-private `save_new_objects()` helper, so a formset subclass that overrides that helper still creates new objects despite `edit_only=True`; fvk moved the guard up into `save()` (exactly where gold put it), closing the hole.
- **Pitch-worthiness (1-5):** 3

## The issue
Model formsets had no reliable "edit only" mode. `extra=0` is only a *display* hint — a client can add forms via JavaScript or by editing the management-form `TOTAL_FORMS`/`INITIAL_FORMS` counts and POST extra rows, which the server turns into new objects. The ticket asks for an explicit opt-in (`edit_only=True`) that **disallows new object creation** while still saving edits to existing objects.

## What baseline did
Added `edit_only` and threaded it through `modelformset_factory`, `inlineformset_factory`, and `generic_inlineformset_factory` (identical to fvk and gold). For enforcement, baseline guarded **only** `save_new_objects()`:
```python
def save_new_objects(self, commit=True):
    self.new_objects = []
    if self.edit_only:          # guard here ONLY
        return self.new_objects
    ...
def save(self, commit=True):
    ...
    return self.save_existing_objects(commit) + self.save_new_objects(commit)  # unconditional virtual dispatch
```

## What fvk changed and why
fvk added the guard inside `save()` itself, short-circuiting **before** the virtual dispatch (keeping baseline's helper guard as belt-and-suspenders):
```python
# fvk — save()
if self.edit_only:
    self.new_objects = []
    return self.save_existing_objects(commit)   # never dispatches to save_new_objects()
return self.save_existing_objects(commit) + self.save_new_objects(commit)
```
This is exactly where **gold** placed its only guard. Because `save()` calls `self.save_new_objects(commit)` *virtually*, a subclass that overrides `save_new_objects()` without `super()` bypasses baseline's helper guard — but cannot bypass fvk's/gold's `save()` guard.

## Concrete demonstration (executed, not asserted)
Three trees built from the pristine base commit (`baseline.patch` / `fvk.patch` / `gold.patch`), run against the local Django (PYTHONPATH pinned to each tree — a venv's Django 4.2 initially shadowed the trees and gave a false pass; corrected and re-verified):
```python
class _CustomFormSet(BaseModelFormSet):
    def save_new_objects(self, commit=True):      # realistic override, no super()
        self.new_objects = []
        for form in self.extra_forms:
            if form.has_changed() and not (self.can_delete and self._should_delete_form(form)):
                self.new_objects.append(self.save_new(form, commit=commit))
        return self.new_objects

AuthorFormSet = modelformset_factory(Author, formset=_CustomFormSet, fields='__all__', edit_only=True)
data = {'form-TOTAL_FORMS':'2','form-INITIAL_FORMS':'0','form-MAX_NUM_FORMS':'0',
        'form-0-name':'Arthur Rimbaud','form-1-name':'Walt Whitman'}
fs = AuthorFormSet(data); fs.is_valid(); fs.save()
Author.objects.count()   # contract says MUST stay 0
```

| Tree | override runs? | `Author.objects.count()` | Demo |
|------|----------------|--------------------------|------|
| **baseline** | yes (via `save()` virtual dispatch) | **2** — `['Arthur Rimbaud','Walt Whitman']` | **FAIL** (contract violated) |
| **fvk** | no (short-circuited in `save()`) | **0** | OK |
| **gold** | no (short-circuited in `save()`) | **0** | OK |

## Why the tests missed it
The 3 official `FAIL_TO_PASS` tests (`test_edit_only`, `test_edit_only_inlineformset_factory`, `test_edit_only_object_outside_of_queryset`) all use the **stock** factories with no custom `save_new_objects()` override. On the stock class baseline's helper guard *is* reached, so all three pass on baseline (verified). The full 73-test `model_formsets` suite also passes identically on baseline and fvk. The tests never subclass and re-implement `save_new_objects()`, so they never exercise the virtual-dispatch path where the guard's *location* matters.

## Gold comparison
Gold uses a single guard, in `save()` only, leaving `save_new_objects()` untouched. fvk matches gold at this exact site (and adds a redundant helper guard). Baseline placed its guard at the *opposite* site from gold (helper, not `save()`) and omitted it where gold actually put it. fvk is strictly closer to gold. **GOLD_MATCH: yes.**

## Confidence & caveats
- **High confidence** the divergence is real and reproducible (three separate built trees; baseline creates 2, fvk/gold create 0).
- **Honest severity caveat:** the divergence only manifests when application code subclasses the formset and overrides `save_new_objects()` without `super()`. `save_new_objects()` is *not* a documented public hook, so it's a semi-private extension point. The documented hooks `save_new()`/`save_existing()` do **not** distinguish baseline from fvk.
- Genuine correctness improvement landing on the maintainers' fix location, but narrow trigger → pitch 3. FVK's own finding F-2 predicted exactly this mechanism; it was empirically confirmed.

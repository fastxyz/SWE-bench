## FVK decisions

I changed `repo/django/forms/models.py` after the FVK audit found V1's guard was
too low in the dispatch stack. Finding F-2 shows that `BaseModelFormSet.save()`
still called `self.save_new_objects(commit)` in V1, so a custom formset subclass
could override `save_new_objects()` and create objects even with
`edit_only=True`. Proof obligation PO-7 requires the public `save()` entry point
to avoid that virtual dispatch in edit-only mode. V2 now checks
`self.edit_only` inside `save()`, initializes `self.new_objects = []`, and
returns `save_existing_objects(commit)` before `save_new_objects()` can be
called.

I kept the V1 guard in `BaseModelFormSet.save_new_objects()`. Finding F-1 and
proof obligation PO-4 require direct calls to the base helper to create no new
objects and leave `new_objects` initialized to an empty list when edit-only mode
is enabled.

I kept the V1 public API additions in `modelformset_factory()`,
`inlineformset_factory()`, and `generic_inlineformset_factory()`. Finding F-3
and proof obligation PO-6 require the public factory paths to expose or
propagate `edit_only`; proof obligation PO-8 confirms the keywords are appended
compatibly and existing in-repo callsites remain unaffected.

I did not change validation, management-form count handling, or extra-form
construction. Finding F-4 records that the public issue requires a way to
disallow new object creation, not a change to validation semantics, and proof
obligations PO-2 through PO-5 are discharged by a save-time creation guard while
preserving existing-object saves and default creation behavior.

I did not modify tests or run any commands beyond static file inspection.
Finding F-6 and proof obligation PO-9 require the proof to remain labeled
constructed, not machine-checked, in this no-execution benchmark environment.

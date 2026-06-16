# FVK Proof Obligations

Status: constructed, not machine-checked.

## PO-1: Intent adequacy

The formal claims must be derived from public issue intent, not from V1/V2
behavior alone.

Evidence: SPEC entries I-1 through I-7 and E-1 through E-7.

Discharge status: satisfied. The claims encode the public requirement to
disallow new object creation in an explicit edit-only mode, while preserving
normal creation when the mode is disabled.

## PO-2: Edit-only `save()` creates zero new objects

For all `E >= 0` and `N >= 0`, `save(true, E, N)` must terminate with
`created = 0`, `newObjects = 0`, and `result = E`.

Evidence: issue evidence E-1 through E-3 and Finding F-1.

Discharge status: satisfied by the V2 guard in `BaseModelFormSet.save()` before
the call to `save_new_objects()`.

## PO-3: Existing-object saves are preserved in edit-only mode

For all `E >= 0`, edit-only `save()` must still return the existing-object save
result represented by `E`.

Evidence: intent entry I-3 and Finding F-1.

Discharge status: satisfied. The V2 edit-only branch calls
`save_existing_objects(commit)` and returns its result.

## PO-4: `new_objects` is initialized empty in edit-only mode

After edit-only `save()` or a direct base `save_new_objects()` call,
`new_objects` must exist and be empty.

Evidence: compatibility with callers such as admin logging that may inspect
`formset.new_objects`, and Findings F-1 and F-2.

Discharge status: satisfied. V2 sets `self.new_objects = []` in the edit-only
`save()` branch, and the base `save_new_objects()` method initializes and
returns the same empty list under `edit_only`.

## PO-5: Default creation behavior is preserved

For all `E >= 0` and `N >= 0`, `save(false, E, N)` must terminate with
`created = N`, `newObjects = N`, and `result = E + N`.

Evidence: intent entry I-4 and Finding F-5.

Discharge status: satisfied. The normal `save()` return expression is unchanged
when `self.edit_only` is false.

## PO-6: Public factory propagation

The public factories must set or propagate the caller's `edit_only` value to
the returned formset class.

Evidence: intent entries I-1, I-5, I-6 and Finding F-3.

Discharge status: satisfied. `modelformset_factory()` sets
`FormSet.edit_only = edit_only`; `inlineformset_factory()` and
`generic_inlineformset_factory()` pass the keyword through.

## PO-7: Virtual-dispatch safety at the public `save()` entry point

Edit-only behavior must not rely solely on the base implementation of a method
that is reached by virtual dispatch from `save()`.

Evidence: implementation entry E-7, compatibility entry C-5, and Finding F-2.

Discharge status: satisfied by V2. The primary edit-only guard is in
`BaseModelFormSet.save()` before `self.save_new_objects(commit)` can be called.

## PO-8: Public API compatibility

The new keyword must be optional and appended to existing public factory
signatures, and in-repo public callsites must remain compatible.

Evidence: compatibility entries C-1 through C-4.

Discharge status: satisfied by static inspection. Existing calls do not pass
arguments after the old tail position.

## PO-9: Honesty gate

The proof must be labeled constructed, not machine-checked, and no tests may be
removed or executed in this environment.

Evidence: benchmark no-exec rule and Finding F-6.

Discharge status: satisfied. The artifacts include commands for a future
machine check but do not claim they were run.

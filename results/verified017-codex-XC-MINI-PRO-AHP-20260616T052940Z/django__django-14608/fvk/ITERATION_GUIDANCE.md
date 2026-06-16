# Iteration Guidance

Status: V1 stands. No V2 source change is required by this FVK pass.

## Decision

Keep the V1 source changes:

- `repo/django/forms/formsets.py` passes `error_class='nonform'` at both
  `_non_form_errors` construction sites.
- `repo/docs/topics/forms/formsets.txt` documents the new rendered class.

## Why no source change is needed

F1 is the only confirmed code bug for the issue. PO-1 and PO-2 are the source
obligations needed to resolve it, and V1 satisfies both. PO-3 and PO-4 confirm
that the change preserves error contents and public value shape. PO-5 confirms
the documentation obligation. PO-6 explains why legacy no-class rendering
expectations are suspect and should not be preserved.

## Next tests to add outside this benchmark

Do not edit tests in this task. In a normal development pass, add or update
tests by inspection target:

- `formset.non_form_errors().error_class == "errorlist nonform"` for a custom
  `BaseFormSet.clean()` `ValidationError`;
- the same class assertion for management-form errors;
- a custom `ErrorList` that records the `error_class` constructor argument and
  observes `nonform`;
- an admin/rendering expectation updated from plain `ErrorList([...])` to
  `ErrorList([...], error_class="nonform")` or equivalent rendered HTML.

## Future FVK work

Machine-check the recorded K artifacts in an environment with K installed.
Until `kprove` returns `#Top`, the proof remains constructed, not
machine-checked, and test-removal recommendations remain conditional.

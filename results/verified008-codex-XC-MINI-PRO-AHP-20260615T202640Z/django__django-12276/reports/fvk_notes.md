# FVK Notes

## Decisions

1. Kept the V1 source-code fix in `repo/django/forms/widgets.py`.

   - Traced to `fvk/FINDINGS.md` F1, F3, and F4.
   - Traced to `fvk/PROOF_OBLIGATIONS.md` PO-1 through PO-7.
   - Reason: the proof obligations cover the reported failing case, the
     required no-initial case, the field/form gates, the server-side
     `FileField.clean()` preservation predicate, and inheritance compatibility
     for `ClearableFileInput` and `AdminFileWidget`.

2. Added a V2 documentation consistency edit in
   `repo/docs/ref/forms/widgets.txt`.

   - Traced to `fvk/FINDINGS.md` F2.
   - Traced to `fvk/PROOF_OBLIGATIONS.md` PO-8.
   - Reason: after V1 moved the behavior to `FileInput`, the public
     `Widget.use_required_attribute(initial)` docs still named only
     `ClearableFileInput` as the special case. The docs now name `FileInput`,
     which includes `ClearableFileInput` by inheritance.

3. Did not modify tests or execute tests, Python, `kompile`, `kast`, or
   `kprove`.

   - Traced to `fvk/FINDINGS.md` F5.
   - Traced to the constructed-only status in all proof obligations.
   - Reason: the task forbids execution and test-file edits. The artifacts
     include the commands needed for later machine-checking and keep all proof
     claims labeled "constructed, not machine-checked."

## Rejected Alternatives

- Changing `BoundField.build_widget_attrs()` was rejected because F1 localizes
  the bug to the widget gate, and PO-3/PO-4 require the existing field/form
  gates to remain unchanged.
- Reintroducing a duplicate `ClearableFileInput.use_required_attribute()` was
  rejected because F4 and PO-5 show inheritance preserves the same behavior.
- Using object identity rather than truthiness for "initial data exists" was
  rejected because PO-6 ties the render decision to `FileField.clean()`, which
  preserves truthy initial values.

## Residual Risk

The FVK proof is constructed only. Source inspection and the finite boolean K
model support the V2 decision, but machine confidence requires later execution
of the emitted `kompile`, `kast`, and `kprove` commands.

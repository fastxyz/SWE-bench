# FVK Notes

## Decision

V1 stands unchanged. No additional source edits were made during the FVK pass.

## Trace to Findings and Proof Obligations

F1 and PO2 show that the original bug was the unconditional generated
`get_<field>_display()` assignment in `Field.contribute_to_class()`. V1 already
fixes this by skipping generation when the display method name is present in
`cls.__dict__`.

F2 and PO1 show that V1 also covers both class-body declaration orders. Because
`ModelBase.__new__()` creates the class with ordinary methods before field
contribution, an explicit display method is present in `cls.__dict__` whether it
appears before or after the field in the class body.

F3 and PO4 justify keeping V1's `cls.__dict__` guard rather than changing it to
the public hint's `hasattr()` form. `hasattr()` would also see inherited
generated methods, which can interfere with generating a display method for a
copied abstract-base field on the child class.

PO3 confirms that V1 preserves the documented default behavior: when a choices
field has no direct explicit override, Django still installs
`partialmethod(cls._get_FIELD_display, field=self)`.

F4 and PO6 identify inherited user-defined display methods as an ambiguity. The
allowed public evidence does not require changing that behavior, so no source
change was made for it.

F5 and PO7 record the honesty gate: this is a constructed proof over an abstract
mini-model, not a machine-checked proof, and no tests or code were executed.

## Source Changes

No source files were changed during this FVK pass. The only production change
remains the V1 edit in `repo/django/db/models/fields/__init__.py`.

## Artifacts Produced

The FVK pass produced:

- `fvk/SPEC.md`
- `fvk/FINDINGS.md`
- `fvk/PROOF_OBLIGATIONS.md`
- `fvk/PROOF.md`
- `fvk/ITERATION_GUIDANCE.md`
- supporting abstract K artifacts: `fvk/mini-django-model-construction.k` and
  `fvk/django-display-spec.k`

No test files were modified.

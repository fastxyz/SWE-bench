# PUBLIC_COMPATIBILITY_AUDIT

Status: constructed, not machine-checked.

Changed public symbol: none.

Changed file: `repo/sympy/geometry/point.py`.

Compatibility review:

- `Point.__new__` signature is unchanged.
- `Point2D.__new__` and `Point3D.__new__` signatures are unchanged.
- `sympify` and parser behavior are unchanged.
- The point-level `evaluate` keyword is still read into the local `evaluate`
  variable and still controls float rationalization/simplification later in the
  constructor.
- The new imported alias `evaluate_context` is private to this module and does
  not alter exported API shape.
- No subclass override or public callsite needs an argument-shape change.

Result: PO-006 satisfied by source diff inspection.

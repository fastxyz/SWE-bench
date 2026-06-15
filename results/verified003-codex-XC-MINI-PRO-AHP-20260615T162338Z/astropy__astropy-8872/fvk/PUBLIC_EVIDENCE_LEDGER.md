# Public Evidence Ledger

Status: public evidence only. Candidate code is used as implementation
evidence, not as the source of expected behavior.

## Ledger

E-001

- Source: prompt / issue
- Evidence: "`float16` quantities get upgraded to `float64` automatically"
- Semantic obligation: default construction from `np.float16` with a unit must
  preserve `float16` dtype rather than promote to `float64`.
- Status: encoded by `PO-1`, `PO-2`, `PO-3`, and K claims `QD-001` and
  `QD-002`.

E-002

- Source: prompt / issue examples
- Evidence: `np.float32`, `np.float64`, and `np.float128` quantities preserve
  their dtype.
- Semantic obligation: dtype preservation is a family behavior for floating
  dtypes, not a one-off exception.
- Status: encoded by `PO-2`, `PO-4`, and K claims `QD-002` and `QD-003`.

E-003

- Source: public hint
- Evidence: old code checked `np.can_cast(np.float32, value.dtype)` and "half
  floats were never considered"; "allow every inexact type."
- Semantic obligation: the default preservation predicate should be NumPy
  inexact dtype membership, not safe castability from `float32`.
- Status: encoded by `PO-2`, `PO-4`, `F-001`, and `F-002`.

E-004

- Source: docstring / public tests
- Evidence: explicit `dtype` is used; if not, integer and bool are converted to
  float; `float32` is preserved; Decimal object defaults to float.
- Semantic obligation: preserve existing explicit-dtype and non-inexact default
  behavior.
- Status: encoded by `PO-5`, `PO-6`, `PO-7`, and K claims `QD-004` through
  `QD-008`.

E-005

- Source: implementation
- Evidence: `UnitBase.__rmul__` returns `Quantity(m, self)` for numeric operands
  without a unit.
- Semantic obligation: the reported multiplication path is discharged if
  `Quantity.__new__` preserves the dtype for the no-explicit-dtype,
  non-`Quantity` path.
- Status: encoded by `PO-1`.

E-006

- Source: implementation / compatibility audit
- Evidence: V1 changes only the default preservation predicate in
  `Quantity.__new__`; no signature or call protocol changes.
- Semantic obligation: no public caller or subclass update is needed.
- Status: encoded by `PO-9` and `F-004`.

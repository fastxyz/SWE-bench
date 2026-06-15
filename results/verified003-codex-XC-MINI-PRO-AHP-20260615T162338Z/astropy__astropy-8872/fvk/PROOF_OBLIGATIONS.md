# Proof Obligations

Status: constructed, not machine-checked.

## Obligations

PO-1. Unit multiplication path.

- Claim: for numeric operands without a `unit` attribute,
  `UnitBase.__rmul__` delegates to `Quantity(m, self)` without supplying
  `dtype`.
- Evidence: `repo/astropy/units/core.py::UnitBase.__rmul__`.
- Discharges: the reported `(np.float16(1) * u.km)` path reaches the
  non-`Quantity`, no-explicit-dtype constructor branch.
- Status: discharged by source inspection and `QD-001`.

PO-2. Non-`Quantity` inexact dtype preservation.

- Claim: for any inexact input dtype `D`, if `dtype is None`, the
  non-`Quantity` constructor branch preserves `D`.
- Evidence: public hint "allow every inexact type".
- Discharges: general family behavior for `float16`, `float32`, `float64`,
  extended float, and complex dtypes.
- Status: discharged by V1 predicate and `QD-002`.

PO-3. Concrete `float16` reproducer.

- Claim: `Quantity(np.float16(1), u.km)` and the equivalent unit multiplication
  path produce dtype `float16` when no explicit dtype is supplied.
- Evidence: issue reproducer and public hint.
- Status: discharged as an instance of `PO-1` and `PO-2`; encoded by `QD-001`.

PO-4. Existing-`Quantity` copy branch inexact preservation.

- Claim: copying an existing `Quantity` with an inexact dtype and no explicit
  dtype preserves that dtype.
- Evidence: the public hint names both old predicate sites; one is in the
  existing-`Quantity` branch.
- Status: discharged by the same V1 predicate and `QD-003`.

PO-5. Explicit dtype override frame condition.

- Claim: if `dtype` is supplied, the constructor uses that dtype.
- Evidence: docstring and public tests.
- Status: unchanged by V1; encoded by `QD-004`.

PO-6. `copy=False` existing-`Quantity` frame condition.

- Claim: for an existing `Quantity`, `copy=False` and no explicit dtype returns
  the existing dtype unchanged.
- Evidence: implementation and public tests for copy behavior.
- Status: unchanged by V1; encoded by `QD-005`.

PO-7. Non-inexact default coercion frame condition.

- Claim: integer, bool, and numeric object dtype default inputs continue to
  produce float dtype unless an explicit dtype is supplied.
- Evidence: docstring and public tests.
- Status: unchanged by V1; encoded by `QD-006` and `QD-007`.

PO-8. Structured dtype frame condition.

- Claim: dtypes with `fields` continue to bypass default float coercion.
- Evidence: existing code exception `or value.dtype.fields`.
- Status: unchanged by V1; encoded by `QD-008`.

PO-9. Public compatibility.

- Claim: no public API signature, dispatch shape, or tests are changed.
- Evidence: V1 source diff and compatibility audit.
- Status: discharged by `fvk/PUBLIC_COMPATIBILITY_AUDIT.md`.

## No Loop Obligations

The audited fragment has no loop or recursion. The proof obligations are
straight-line branch obligations over dtype categories.

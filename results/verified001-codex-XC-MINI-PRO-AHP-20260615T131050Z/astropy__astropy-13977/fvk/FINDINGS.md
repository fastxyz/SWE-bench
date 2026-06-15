# FVK Findings

Status: constructed, not machine-checked. No tests, Python, or K tooling were
run.

## F1 - Pre-fix converter claims unknown unit-bearing duck arrays

Input: `np.add(1 * u.m, DuckArray(1 * u.mm))`, where `DuckArray` is not a
`Quantity` or `numpy.ndarray` subclass but exposes `.unit` and implements
`__array_ufunc__`.

Observed before V1: `Quantity.__array_ufunc__` used `.unit`, computed a unit
converter, then applied that converter to the `DuckArray` object itself. The
traceback in the public issue shows `ValueError` from `_condition_arg`.

Expected: `Quantity.__array_ufunc__` returns `NotImplemented` before converter
application so NumPy can try the duck array's reflected ufunc handling.

Status: fixed by V1. Covered by proof obligations PO1, PO2, and PO5.

## F2 - Non-ndarray unit-bearing `__array__` mimics are intentionally delegated

Input: a non-ndarray object with `.unit` and `__array__`, but no Quantity or
ndarray inheritance.

Observed after V1: `Quantity.__array_ufunc__` returns `NotImplemented` instead
of coercing through `__array__`.

Expected: delegate rather than coerce. The public hint explicitly says an
`__array__` workaround might make old code work, but that "not even trying" is
the right solution.

Status: intentional behavior, not a V1 defect. Covered by PO2 and PO3.

## F3 - Column compatibility remains in scope and is preserved

Input: `Quantity` interacting with an Astropy table `Column` or `MaskedColumn`.

Observed in source: `BaseColumn` subclasses `numpy.ndarray`, and V1 accepts all
`np.ndarray` instances before checking `.unit`.

Expected: Columns continue to use the existing Quantity converter path.

Status: preserved by V1. Covered by PO4.

## F4 - FunctionQuantity has a separate unsupported-ufunc policy

Input: a function quantity such as a logarithmic quantity with a ufunc outside
its `_supported_ufuncs`.

Observed in source: `FunctionQuantity.__array_ufunc__` raises `UnitTypeError`
before delegating to `Quantity.__array_ufunc__`.

Expected for this task: no change. The public issue and hint localize the defect
to generic `Quantity.__array_ufunc__` treating every `.unit` object as
Quantity-like during converter selection. Function quantities have an explicit,
separate class-level unsupported-ufunc policy.

Status: out of scope for this fix. Future work should formalize that policy
separately if duck-array delegation is desired there too.

## F5 - Full NumPy/Astropy ufunc semantics are an escalation boundary

Input: arbitrary ufunc methods, all unit helpers, all subclasses, and NumPy's
complete dispatch ordering.

Observed in this FVK pass: the constructed K model covers the early dispatch
gate and abstracts the rest as `PROCEED`.

Expected: sufficient for this issue because the reported bug is precisely
whether the early path reaches converter application for an unrecognized
unit-bearing duck array.

Status: explicit proof capability boundary. It does not block V1 because the
modeled property is the behavioral axis named by the issue.


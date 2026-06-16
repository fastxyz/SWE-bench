# SPEC

Status: constructed, not machine-checked.

## Target

This FVK pass audits the imaginary-coordinate validation inside
`repo/sympy/geometry/point.py:Point.__new__`, after coordinates have been
sympified into a `Tuple` and before the point is instantiated as `Point2D`,
`Point3D`, or general `Point`.

The modeled code slice is:

```python
with evaluate_context(True):
    if any(a.is_number and im(a) for a in coords):
        raise ValueError('Imaginary coordinates are not permitted.')
```

## Intent Spec

I-001. A `Point2D` parsed inside `evaluate(False)` from real integer coordinates
must not raise `ValueError('Imaginary coordinates are not permitted.')`.

I-002. The imaginary-coordinate guard is a mathematical validation rule, not a
request to preserve the ambient expression-building mode. It must classify
numeric coordinates the same way as the normal evaluated path.

I-003. Numeric coordinates with a nonzero evaluated imaginary part remain
invalid and must still raise the existing `ValueError`.

I-004. Non-numeric symbolic coordinates remain outside this guard, matching the
documented examples that accept symbolic coordinates such as `Point(0, x)`.

I-005. The ambient value of `global_parameters.evaluate` must be restored after
the validation probe.

## Public Evidence Ledger

E-001. Source: prompt. Quote: "`with evaluate(False)` crashes unexpectedly with
`Point2D`" and the reproduction `sp.S('Point2D(Integer(1),Integer(2))')`.
Obligation: real integer coordinates are in-domain under ambient
`evaluate(False)` and must construct without the imaginary-coordinate error.
Status: encoded by PO-001 and claims `POINT-VALIDATE-PASS` /
`POINT-VALIDATEEVAL-PASS`.

E-002. Source: prompt. Quote: "However, it works without `with
evaluate(False)`." Obligation: the coordinate validation result should not
depend on the ambient global evaluation flag for real numeric coordinates.
Status: encoded by PO-002.

E-003. Source: public tests/docs. Quote from geometry tests: `raises(ValueError,
lambda: Point(3, I))`, `Point(2*I, I)`, and `Point(3 + I, I)`. Obligation:
numeric coordinates with nonzero imaginary part continue to raise.
Status: encoded by PO-003.

E-004. Source: point docstring. Quote: `Point(0, x)` gives `Point2D(0, x)`.
Obligation: symbolic/non-numeric coordinates are not rejected by the numeric
imaginary-coordinate guard.
Status: encoded by PO-004.

E-005. Source: implementation/API. Quote: `evaluate = kwargs.get('evaluate',
global_parameters.evaluate)` and the point docs describe `evaluate` as
controlling float rationalization. Obligation: the point-level `evaluate` option
must remain available for coordinate simplification behavior, while the
temporary validation probe restores the ambient global flag.
Status: encoded by PO-005.

## Abstract Domain

The K model abstracts a coordinate into one of four classes:

- `realNum`: numeric coordinate whose evaluated imaginary part is zero.
- `residualZeroNum`: numeric coordinate whose imaginary part is mathematically
  zero but can leave a truthy residual if helper constructors inside `im.eval`
  run with ambient `evaluate(False)`.
- `complexNum`: numeric coordinate whose evaluated imaginary part is nonzero.
- `symbolicCoord`: non-numeric coordinate ignored by this guard.

This abstraction keeps the property under verification visible: numeric-vs-
symbolic classification, nonzero imaginary rejection, real numeric acceptance,
and dependence on the ambient evaluation flag.

## Contract

C-001. For every finite coordinate list `CS`, if no coordinate is numeric with a
nonzero imaginary part under evaluated semantics, validation reaches `ok`.

C-002. For every finite coordinate list `CS`, if any coordinate is numeric with
a nonzero imaginary part under evaluated semantics, validation reaches
`imaginaryError`.

C-003. For every finite coordinate list `CS` and old ambient evaluation flag
`OLD`, validation restores `<eval>` to `OLD`.

C-004. `residualZeroNum` is accepted under the V2 validation because the guard
uses evaluated semantics for the entire `im` probe. This is the difference from
V1, where only the top-level `im` call was forced.

## Formal Files

- `fvk/mini-sympy-point.k`: mini-K semantics for this validation slice.
- `fvk/point-imaginary-validation-spec.k`: K claims for C-001 through C-004.

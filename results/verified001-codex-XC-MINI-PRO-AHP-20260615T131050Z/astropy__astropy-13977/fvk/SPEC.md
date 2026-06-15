# FVK Specification: Quantity ufunc duck-array dispatch

Status: constructed, not machine-checked. No tests, Python, or K tooling were
run.

## Scope

This FVK pass audits the V1 change in
`repo/astropy/units/quantity.py::Quantity.__array_ufunc__`. The formal model is
limited to the new dispatch gate before `converters_and_unit()` and
`check_output()`. The rest of Astropy's unit conversion and NumPy ufunc
semantics are modeled as the abstract result `PROCEED`.

This is the right abstraction for the issue because the reported failure occurs
before NumPy can dispatch to the duck array: `Quantity.__array_ufunc__` treats an
unknown object with `.unit` as quantity-like, computes a converter, and applies
that converter to the foreign object.

## Intent-Only Obligations

I1. If `Quantity.__array_ufunc__` sees any input or output object that is not a
recognized Quantity/ndarray object but does expose `unit`, it must return
`NotImplemented` before unit converter lookup or converter application.

I2. Recognized objects remain on the existing Quantity path. Recognized means
`Quantity` itself or an `numpy.ndarray` subclass. Table `Column` and
`MaskedColumn` are included because `BaseColumn` subclasses `numpy.ndarray`.

I3. Objects without a `unit` attribute, `None` outputs, plain scalars, and plain
arrays remain on the existing path.

I4. The check covers both `inputs` and `out`, matching the public hint's
`inputs+out` shape.

I5. This audit does not change `FunctionQuantity.__array_ufunc__`'s separate
policy for unsupported function-unit ufuncs. That path is a distinct class
policy, not the reported generic `Quantity` converter failure.

## Public Evidence Ledger

E1. Source: prompt. Quote: "`Quantity.__array_ufunc__()` should really return
`NotImplemented` in this instance, since it would allow for `__radd__` to be
called instead of the error being raised." Obligation: I1.

E2. Source: prompt traceback. Quote: `arrays.append(converter(input_) if
converter else input_)` followed by `ValueError` in `_condition_arg`. Obligation:
converter application to the duck object must not occur for unrecognized
unit-bearing duck arrays.

E3. Source: public hint. Quote: "one only works on classes that are recognized,
while ... essentially everything that has a `unit` attribute is treated as a
`Quantity`." Obligation: distinguish recognized classes from merely
unit-bearing duck arrays.

E4. Source: public hint. Quote: "The only example that perhaps will fail (but
should continue to work) is of `Quantity` interacting with a `Column`."
Obligation: preserve `Column` compatibility.

E5. Source: public hint. Quote: "equivalent to `if not all(isinstance(io,
(Quantity, ndarray, Column) for io in *(inputs+out)): return NotImplemented`".
Obligation: guard both inputs and outputs, while preserving ndarray subclasses.

E6. Source: public hint. Quote: defining `__array__` might make current code
work, "but ... not even trying" is the right solution. Obligation:
non-ndarray unit-bearing mimics with only `__array__` should not be coerced by
`Quantity.__array_ufunc__`.

E7. Source: implementation. `BaseColumn` is declared as
`class BaseColumn(_ColumnGetitemShim, np.ndarray)`. Obligation: V1's
`isinstance(obj, np.ndarray)` preserves Column behavior without importing
`Column` into `quantity.py`.

E8. Source: implementation. `converters_and_unit()` documents inputs as
"`Quantity` or ndarray subclass" and obtains units using `getattr(arg, "unit",
None)`. Obligation: the dispatch gate should run before this broad `.unit`
inspection.

## Formal Model

The supporting K artifacts are:

- `fvk/mini-ufunc-dispatch.k`
- `fvk/quantity-ufunc-dispatch-spec.k`

The model classifies each input/output object into one of these abstract values:

- `Q`: a Quantity instance or subclass.
- `ND`: a `numpy.ndarray` instance or subclass, including table Columns.
- `NONE`: a `None` output slot.
- `OTHER_PLAIN`: a non-recognized object without `unit`.
- `OTHER_UNIT`: a non-recognized object with `unit`.

The modeled function is:

`quantityArrayUfunc(inputs, outputs) = guard(concat(inputs, outputs))`

where `guard` returns `NOT_IMPLEMENTED` iff at least one element is
`OTHER_UNIT`; otherwise it returns `PROCEED`.

## Claims

C1. Unsupported unit-bearing input/output:
For all input and output lists, if `concat(inputs, outputs)` contains
`OTHER_UNIT`, `quantityArrayUfunc(inputs, outputs)` reaches
`NOT_IMPLEMENTED`.

C2. Recognized or non-unit input/output:
For all input and output lists, if `concat(inputs, outputs)` contains no
`OTHER_UNIT`, `quantityArrayUfunc(inputs, outputs)` reaches `PROCEED`.

C3. Converter exclusion:
On C1 paths, the result is `NOT_IMPLEMENTED` before the abstract converter path
is entered. This discharges the reported `ValueError` symptom by removing the
converter application to the duck object.

C4. Column compatibility:
`ND` is an accepted class in C2, so ndarray subclasses, including table Columns,
remain on the existing path.

## Adequacy Summary

The formal model distinguishes the failing pre-fix case from the fixed case:

- Pre-fix abstraction: `OTHER_UNIT` could proceed to converter application.
- V1 abstraction: `OTHER_UNIT` reaches `NOT_IMPLEMENTED`.

It also distinguishes the compatibility cases that must remain unchanged:

- `Q`, `ND`, `NONE`, and `OTHER_PLAIN` all reach `PROCEED`.

Therefore the abstraction preserves the behavioral axis under audit: whether
`Quantity.__array_ufunc__` claims and converts an unknown unit-bearing duck array
or delegates by returning `NotImplemented`.


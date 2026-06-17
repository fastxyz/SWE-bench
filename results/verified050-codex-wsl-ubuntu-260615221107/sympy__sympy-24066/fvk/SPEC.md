# FVK Specification

Status: constructed, not machine-checked. No tests, Python, `kompile`, or
`kprove` were run.

## Target

The audited unit is `UnitSystem._collect_factor_and_dimension()` in
`repo/sympy/physics/units/unitsystem.py`, specifically:

- the `Function` branch for expressions such as `exp(arg)`;
- the `Add` branch for dimension compatibility;
- V2 helper methods `_is_dimensionless()` and `_dimensions_equivalent()`.

There are no loops in the audited code slice. The proof obligations are
reachability contracts over the relevant branches.

## Public Intent Ledger

| ID | Source | Evidence | Semantic obligation | Status |
| --- | --- | --- | --- | --- |
| I1 | prompt | "`SI._collect_factor_and_dimension() cannot properly detect that exponent is dimensionless`" | The collector must use the unit system's dimension knowledge, not only structural equality, when deciding that a function argument is dimensionless. | Encoded in FS1 and PO1. |
| I2 | prompt | `assert SI.get_dimension_system().is_dimensionless(dim)` for `second/(ohm*farad)` | `Dimension(time/(capacitance*impedance))` is in-domain and must be treated as dimensionless under SI. | Encoded in FS1. |
| I3 | prompt | Error says `Dimension ... but it should be Dimension(1)` | `exp(second/(ohm*farad))` must collect with result dimension `Dimension(1)`. | Encoded in FS2. |
| I4 | prompt | `buggy_expr = 100 + exp(expr)` followed by collection | Adding a dimensionless number and that exponential must not raise a dimension mismatch. | Encoded in FS3. |
| I5 | public test | `raises(ValueError, lambda: check_unit_consistency(u + w))` and similar incompatible additions | Incompatible additions must still raise `ValueError`. | Encoded in FS4 and PO3. |
| I6 | public test | `raises(ValueError, lambda: check_unit_consistency(1 - exp(u / w)))` | A function of a dimensionful argument remains incompatible with dimensionless addends under existing collector behavior. | Preserved by FS4. |
| I7 | public test | `assert (1, volume/amount_of_substance) == SI._collect_factor_and_dimension(exp(pH))` | Do not change `_collect_factor_and_dimension()` into a strict mathematical-function validator that rejects all dimensionful function arguments. | Frame condition FC1. |
| I8 | implementation | `DimensionSystem.is_dimensionless()` returns true when dimensional dependencies are `{}` | The dimension system is the oracle for reducing derived dimensions to dimensionless. | Encoded in helper contract H1. |
| I9 | FVK audit finding | V1 inline checks could leak `TypeError` from dependency analysis in additive compatibility checks. | An unanalyzable non-equal dimension pair should be treated as not equivalent by the new helper, keeping the collector on its `ValueError` path. | V2 change, encoded in H2 and FS5. |

## Abstract Domain

The formal model abstracts away unrelated SymPy expression mechanics and keeps
only the observable property under verification:

- `D1`: `Dimension(1)`.
- `DRC`: `Dimension(time/(capacitance*impedance))`, the reproducer argument
  dimension for `second/(ohm*farad)`.
- `DLEN`: a non-dimensionless length-like dimension.
- `DUNSUPPORTED`: a dimension expression that the dimension system cannot reduce.
- `isDimless(D)`: the dimension-system predicate used by
  `_is_dimensionless()`.
- `equivDim(D1, D2)`: the dimension-system equivalence predicate used by
  `_dimensions_equivalent()`.

The model distinguishes a passing case (`DRC` maps to `D1` for function
collection) from a failing case (`DLEN` stays non-dimensionless and cannot be
added to `D1`). It also distinguishes an unsupported case (`DUNSUPPORTED`) so
the V2 helper behavior is non-vacuous.

## Formal Specification

FS1. Dimensionless helper:

For any dimension `D`, `_is_dimensionless(D)` returns true exactly when the
configured dimension system exists and proves `D` dimensionless. If the dimension
system is absent or raises `TypeError`, the helper returns false.

FS2. Function branch:

For any one-argument function expression whose collected argument is `(F, D)`,
the collector returns `(func(F), Dimension(1))` when `_is_dimensionless(D)` is
true. Otherwise it returns `(func(F), D)`. This preserves existing non-strict
function behavior while canonicalizing dimensionless derived dimensions.

FS3. Reported expression:

Under SI, collecting `100 + exp(second/(ohm*farad))` reaches a normal result with
dimension `Dimension(1)`, not a dimension mismatch error.

FS4. Additive incompatibility:

For addends with collected dimensions `D1` and `D2`, the `Add` branch raises
`ValueError` when `_dimensions_equivalent(D1, D2)` is false.

FS5. Conservative equivalence helper:

`_dimensions_equivalent(D1, D2)` returns true for structural equality or when the
configured dimension system proves equivalence. If the dimension system is absent
or raises `TypeError`, it returns false.

FC1. Frame condition:

The patch does not change the public method signature, tuple shape for existing
single-argument function paths, scale-factor collection, derivative handling,
quantity lookup, or the existing non-strict treatment of dimensionful function
arguments.

## Formal Files

- `fvk/mini-sympy-units.k`: minimal K semantics for the collector slice.
- `fvk/unitsystem-collect-spec.k`: K claims for FS2 through FS5.

Exact commands are recorded in `fvk/PROOF.md`; they were not executed.

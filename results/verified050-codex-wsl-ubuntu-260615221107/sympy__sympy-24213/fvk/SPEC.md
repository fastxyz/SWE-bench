# FVK Spec

Status: constructed, not machine-checked. No tests, Python, or K tooling were
run.

## Target

Target function: `UnitSystem._collect_factor_and_dimension` in
`repo/sympy/physics/units/unitsystem.py`.

Audited branch: the `Add` branch, because the public issue reports a false
`ValueError` when adding equivalent dimensions represented by different
`Dimension` expressions.

## Intent Summary

For an addition expression, recursively collect each addend as `(factor,
dimension)`. The addition is valid when every addend's dimension is compatible
with the first addend's dimension. Compatibility means:

- direct dimension equality always accepts;
- with an active `DimensionSystem`, unequal dimensions also accept when
  `DimensionSystem.equivalent_dims(first_dim, addend_dim)` is true;
- without a dimension system, unequal dimensions remain incompatible.

On success, return the sum of all addend factors and the first addend's
dimension expression. On the first incompatible addend, raise `ValueError`.

## Public Intent Ledger

| ID | Source | Evidence | Obligation |
| --- | --- | --- | --- |
| E1 | prompt | "does not detect equivalent dimensions in addition" | Use dimension-system equivalence for addition. |
| E2 | prompt | `a1*t1 + v1` fails because `velocity` is not equal to `acceleration*time`. | Accept equivalent named and compound dimensions. |
| E3 | source | `DimensionSystem.equivalent_dims` compares dimensional dependency dictionaries. | The active dimension system is the right equivalence oracle. |
| E4 | source | SI dependencies make `velocity` and `acceleration*time` both reduce to length over time. | The issue's concrete pair is equivalent. |
| E5 | public-test/source | Existing consistency checks reject length plus time. | Preserve mismatched-dimension `ValueError`. |
| E6 | source | Existing accepted `Add` branch returns the first dimension expression. | Do not canonicalize return dimensions without public intent. |
| E7 | source | `UnitSystem` permits `dimension_system=None`. | Preserve direct-equality fallback there. |

See also `fvk/PUBLIC_EVIDENCE_LEDGER.md`.

## Formal Core

Formal semantics file: `fvk/mini-unit-dimension.k`.

Formal claims file: `fvk/collect-factor-and-dimension-spec.k`.

The K model abstracts the recursive collection of each addend into an input list
of collected factor/dimension pairs. This keeps the modeled observable exactly
on the defect axis: dimension compatibility and factor accumulation in `Add`.

## Adequacy Summary

The formal claims paraphrased in `fvk/FORMAL_SPEC_ENGLISH.md` cover the public
intent in `fvk/INTENT_SPEC.md`. `fvk/SPEC_AUDIT.md` marks each claim as pass.
`fvk/PUBLIC_COMPATIBILITY_AUDIT.md` records no API or call-site incompatibility.

## Frame Conditions

- Non-`Add` branches of `_collect_factor_and_dimension` are outside the changed
  behavior and remain untouched.
- The public method signature is unchanged.
- The returned dimension for accepted additions remains the first addend's
  dimension expression.
- Test files are not modified.

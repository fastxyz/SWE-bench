# SPEC.md

Status: constructed, not machine-checked. No tests, Python, or K tooling were
run.

## Scope

This FVK pass audits the V1 fix for `pydata__xarray-4075`, focused on
`repo/xarray/core/weighted.py`:

- `Weighted._reduce`
- `Weighted._sum_of_weights`
- `Weighted._weighted_mean`

The modeled observable is the one the issue exposes: whether a boolean/boolean
dot reduction produces an integer 0/1 sum or collapses to a boolean truth value.
The model abstracts xarray alignment and dimensions into equal-length lists
after alignment has selected the values participating in the reduction.

## Intent Summary

Boolean weights are valid weights and must behave as numeric 0/1 weights. For
weighted means, the denominator is the sum of weights corresponding to non-null
data. In the reported example, data `[1., 1., 1.]` and boolean weights
`[True, True, False]` require denominator `2`, numerator `2`, and mean `1.0`.

## Public Evidence Ledger

The full ledger is in `fvk/PUBLIC_EVIDENCE_LEDGER.md`. Critical entries:

- E1/E2: the issue labels boolean weights to weighted mean as a bug and states
  expected output `array(1.)`.
- E3/E4: the issue localizes the defect to `xr.dot(dta.notnull(), wgt)` yielding
  `True`; converting to int or float yields numeric denominator `2`.
- E5: `_reduce` states it is equivalent to `(da * weights).sum(dim, skipna)`.
- E6: `_sum_of_weights` feeds `da.notnull()` and `weights` into `_reduce`.
- E7: public tests compute expected denominators with
  `weights.where(da.notnull()).sum(...)`.

## Formal Model

The K artifacts are:

- `fvk/mini-weighted.k`: a mini semantics for boolean lists, integer data
  lists, 0/1 conversion, boolean-weight sums, the cast guard, and the issue
  weighted mean.
- `fvk/weighted-spec.k`: reachability claims for the cast guard, bool/bool
  reduction, sum of weights, zero-weight behavior, and the issue example.

The core abstraction functions are:

- `boolToInt(true) = 1`, `boolToInt(false) = 0`
- `dot01(BS, WS) = sum_i boolToInt(BS_i) * boolToInt(WS_i)`
- `weightedSumBoolWeights(DATA, WEIGHTS) =
  sum_i DATA_i * boolToInt(WEIGHTS_i)`

The model also includes `buggyBoolDot`, an explicit representation of the
pre-fix any-true style boolean collapse, to distinguish the failing behavior
from the intended numeric count.

## Preconditions

- Inputs to the modeled reductions have equal length after xarray alignment.
- Weights contain no missing values, matching the existing `Weighted`
  constructor requirement.
- Partial correctness only: the proof discusses returned values if execution
  reaches the modeled reduction result.

## Required Postconditions

- PO-1: `Weighted._reduce` on boolean data and boolean weights returns the
  integer 0/1 dot sum, not a boolean result.
- PO-2: `Weighted._sum_of_weights` with boolean weights uses that numeric
  reducer result as the denominator.
- PO-3: The issue example returns mean `1.0` because numerator and denominator
  are both `2`.
- PO-4: Zero total weights remain invalid/missing.
- PO-5: Mixed boolean/numeric and numeric paths remain outside the new cast.
- PO-6: Public API signatures and dispatch shape remain unchanged.

## Adequacy

The formal-English paraphrase in `fvk/FORMAL_SPEC_ENGLISH.md` matches the
intent-only requirements in `fvk/INTENT_SPEC.md`; the comparison is recorded in
`fvk/SPEC_AUDIT.md`. No formal claim preserves the reported pre-fix
`array(2.)` mean or the boolean denominator `True` as expected behavior.

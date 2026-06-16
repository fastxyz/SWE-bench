# Proof Obligations

Status: constructed, not machine-checked.

## PO1: Definite diagonal entry

Statement: if index equality is definite, `Identity._entry(i, j)` evaluates to `1`.

Evidence: E1, E2, E5.

Discharge: `Identity._entry` returns `KroneckerDelta(i, j)`, and `KroneckerDelta.eval` returns `S.One` when `i - j` is zero.

Status: discharged by source inspection.

## PO2: Definite off-diagonal entry

Statement: if index inequality is definite, `Identity._entry(i, j)` evaluates to `0`.

Evidence: E1, E5, E6.

Discharge: `Identity._entry` returns `KroneckerDelta(i, j)`, and `KroneckerDelta.eval` returns `S.Zero` when `i - j` is definitely nonzero.

Status: discharged by source inspection.

## PO3: Undecidable symbolic equality is preserved

Statement: if equality between `i` and `j` is not decidable at entry construction time, `Identity._entry(i, j)` must preserve a symbolic equality condition rather than return `0`.

Evidence: E3-E5.

Discharge: `Identity._entry` returns `KroneckerDelta(i, j)`. For undecidable equality, `KroneckerDelta.eval` does not return `S.Zero`.

Status: discharged by source inspection.

## PO4: Delta summation creates an exact interval Piecewise

Statement: summing `KroneckerDelta(i, j)` over `i = a..b` produces a value supported exactly on `Interval(a, b).as_relational(j)`.

Evidence: E7 and existing `deltasummation` implementation.

Discharge: `deltasummation` solves the delta for the summation index and returns `Piecewise((expr.subs(x, value), Interval(*limit[1:3]).as_relational(value)), (S.Zero, True))`.

Status: discharged by source inspection.

## PO5: Exact-interval Piecewise sums over its support

Statement: for known nonnegative interval width, `Sum(Piecewise((expr, Interval(a, b).as_relational(i)), (0, True)), (i, a, b)).doit()` equals `Sum(expr, (i, a, b)).doit()`.

Evidence: E3 and E7.

Discharge: V2 adds an `eval_sum` branch that recognizes this exact two-branch, zero-fallback Piecewise form and recurses on `expr` over the same limits.

Status: discharged by source inspection.

## PO6: Identity row, column, and total sums count diagonal positions

Statement: for positive integer `n`, a fixed row or column sum over `0..n-1` is `1`, and the total double sum is `n`.

Evidence: E2, E3, E6.

Discharge: PO3 preserves `KroneckerDelta`; PO4 converts one summation to exact interval support; PO5 collapses the remaining exact-interval Piecewise; `eval_sum(1, (i, 0, n - 1))` returns `n`.

Status: discharged by constructed proof.

## PO7: Compatibility frame

Statement: concrete identity indexing and unrelated identity matrix methods remain unchanged.

Evidence: E8.

Discharge: `_entry` still returns definite `1` and `0` through `KroneckerDelta` evaluation; no other `Identity` methods or signatures changed. The `eval_sum` change is guarded to one exact Piecewise shape.

Status: discharged by source inspection.

## PO8: Honesty and non-execution constraints

Statement: do not claim machine verification, do not run tests or tooling, and do not modify tests.

Evidence: task instructions and FVK docs.

Discharge: all artifacts are labeled constructed, not machine-checked; commands are recorded but not executed; test files are untouched.

Status: discharged by process.


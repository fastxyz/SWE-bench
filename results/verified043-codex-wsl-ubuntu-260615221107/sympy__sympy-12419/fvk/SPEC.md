# FVK Specification

Status: constructed, not machine-checked. No tests, Python, or K tooling were run.

## Scope

This audit covers the observable behavior needed for the reported SymPy issue:

- `Identity._entry(i, j)` as reached through `Identity(n)[i, j]`.
- The `eval_sum` path for the exact `Piecewise` expression produced by summing a `KroneckerDelta` over one index of an identity matrix.

The audit does not specify all of `Sum`, all `Piecewise` simplification, or every matrix expression class.

## Intent Spec

I1. For an identity matrix, a definitely diagonal entry is `1`.

I2. For an identity matrix, a definitely off-diagonal entry is `0`.

I3. For symbolic row and column indices whose equality is undecidable, the entry must not collapse to `0`; it must preserve the condition "row equals column" so later summation or substitution can count diagonal cases.

I4. For positive integer dimension `n`, the total sum of the entries of an `n` by `n` identity matrix is `n`.

I5. For positive integer dimension `n`, summing a fixed row or fixed column of an identity matrix over its valid index range gives `1`.

I6. Concrete indexing and unrelated identity-matrix properties such as shape, transpose, inverse, trace, and determinant must remain unchanged.

## Public Evidence Ledger

E1. Source: prompt. Quote: "SymPy successfully recognized that the result is an identity matrix." Obligation: treat `e` as an identity matrix for entry and sum semantics. Status: encoded by I1-I5.

E2. Source: prompt. Quote: "The sum of the diagonal elements is n." Obligation: diagonal entries contribute one each. Status: encoded by I1 and I4.

E3. Source: prompt. Quote: "Total sum of the elements is expected to be 'n' but the answer is 0." Obligation: the nested `.doit()` computation must not lose diagonal contributions and should return the count of diagonal entries. Status: encoded by I3-I4.

E4. Source: public hint. Quote: "it assumes that if the indices are different then you are off-diagonal rather than not evaluating them at all because it is not known if i == j." Obligation: symbolic structural inequality is not proof of mathematical off-diagonal status. Status: encoded by I3.

E5. Source: public hint. Quote: "This should just return `KroneckerDelta(i, j)`." Obligation: identity entries should use the canonical discrete equality condition. Status: encoded by PO1-PO3.

E6. Source: public hint. Quote: "`Sum(e[0,i],(i,0,n-1)).doit()` ... shouldn't these be 1." Obligation: row and column one-dimensional sums over the valid range count exactly one diagonal position. Status: encoded by I5 and PO6.

E7. Source: code. `deltasummation` returns `Piecewise((expr.subs(x, value), Interval(*limit[1:3]).as_relational(value)), (S.Zero, True))`. Obligation: when the next summation uses that same interval as its active limits, the Piecewise support is known to cover every summation point. Status: encoded by PO4-PO5.

E8. Source: code. `Identity` methods for shape, transpose, trace, inverse, determinant, and conjugate are separate from `_entry`. Obligation: the fix should not change those methods. Status: encoded by I6 and PO7.

## Formal Claims In English

C1. `Identity._entry(i, j)` returns `KroneckerDelta(i, j)`.

C2. `KroneckerDelta(i, j)` evaluates to `1` when equality is definite, to `0` when inequality is definite, and remains symbolic when equality is undecidable.

C3. Summing `KroneckerDelta(i, j)` over `i = 0..n-1` produces a two-branch `Piecewise` with value `1` exactly when `j` lies in `Interval(0, n - 1)` and `0` otherwise.

C4. Summing a two-branch `Piecewise((expr, Interval(a, b).as_relational(i)), (0, True))` over exactly `i = a..b`, with `b - a` known nonnegative, is equal to summing `expr` over the same limits.

C5. Combining C1-C4, the nested sum over all entries of `Identity(n)` for positive integer `n` is `n`.

C6. Concrete identity entries remain unchanged because `KroneckerDelta` evaluates definite equalities and inequalities immediately.

## Adequacy Audit

I1 maps to C1-C2 and passes.

I2 maps to C1-C2 and passes.

I3 maps to C1-C2 and passes. This is the core V1 obligation.

I4 maps to C1-C5 and required the V2 `eval_sum` improvement. V1 alone preserved the diagonal condition but did not provide the exact-interval Piecewise collapse needed by the original nested-sum output form.

I5 maps to C1-C4 and passes by the same exact-interval reasoning with one fixed endpoint.

I6 maps to C6 and the compatibility audit below, and passes by static inspection.

## Compatibility Audit

Changed public observable: `Identity(n)[i, j]` for undecidable symbolic equality now returns `KroneckerDelta(i, j)` instead of `0`. This is intentional and directly required by E3-E5.

Unchanged public observable: concrete `Identity(3)[0, 0]`, `Identity(3)[0, 1]`, and other definite entry lookups still return `1` or `0` because `KroneckerDelta` evaluates definite cases.

Changed shared helper: `eval_sum` now simplifies only a two-branch, zero-fallback `Piecewise` whose condition is exactly `Interval(a, b).as_relational(i)` and whose active summation limits are exactly `(i, a, b)` with known nonnegative width. This is a narrow generalization of existing Piecewise folding and is required to satisfy E3.

No method signatures, class shapes, or test files were changed.


# FVK Spec - sympy__sympy-17318

Status: constructed, not machine-checked.

## Scope

This FVK pass audits the V1 repair for the issue path through:

- `sympy/simplify/sqrtdenest.py::_sqrt_match`
- `sympy/simplify/radsimp.py::split_surds`
- `sympy/simplify/radsimp.py::_split_gcd`
- `sympy/simplify/radsimp.py::rad_rationalize`

The full SymPy expression evaluator is outside the mini-semantics. The proof
models the branch conditions and return shapes that decide whether unsupported
additive denominators are passed to surd splitting or returned unchanged.

## Public Intent Ledger

I1. Source: prompt.

Quote: "sqrtdenest raises IndexError" and "If an expression cannot be denested
it should be returned unchanged."

Obligation: `sqrtdenest` must not raise `IndexError` when the square-root base
cannot be matched as `a + b*sqrt(r)`; it must preserve the expression instead.

Status: encoded by PO1 and PO2.

I2. Source: public issue hint.

Quote: "Changing the expression to `sqrtdenest(3 - sqrt(2)*sqrt(4 + I) + 3*I)`
raises the same error in current master."

Obligation: the fix must cover flat complex additive bases such as `4 + I`,
not only the auto-evaluating original expression.

Status: encoded by PO1.

I3. Source: public issue hint.

Quote: "`split_surds` is called ... with an argument of `4+I`, which leads to an
empty `surds` list ... completely unexpected by `_split_gcd`."

Obligation: `split_surds` must handle the no-square-root-surd case directly and
must not let an empty list cause `_split_gcd` to index `a[0]`.

Status: encoded by PO2 and PO3.

I4. Source: docstring and public issue hint.

Quote: `rad_rationalize` is documented to remove square roots in the
denominator, and the issue says "`rad_rationalize(1,4+I)` ... shouldn't fail"
plus "`rad_rationalize(1,1+cbrt(2))`" has infinite recursion due to missing
checks.

Obligation: when an additive denominator contains no rationalizable square-root
part, `rad_rationalize` must return `(num, den)` unchanged rather than raising
or recurring forever.

Status: encoded by PO4.

I5. Source: public issue hint.

Quote: "`rad_rationalize(1,sqrt(2)+I)` returns `(sqrt(2) - I, 3)`."

Obligation: valid square-root rationalization must be preserved while rejecting
unsupported no-surd and higher-root cases.

Status: encoded by PO5.

I6. Source: public issue hint.

Quote: "Please do not add bare except statements. We should find the source of
this issue and fix it there."

Obligation: the repair must be branch/source guards, not exception swallowing.

Status: encoded by PO7.

## Function Contracts

### `_sqrt_match(p)`

Domain: SymPy expression `p`.

Contract slice:

- If `p` is an additive expression whose addends square to rationals but not all
  of those squares are positive, `_sqrt_match` must not use the `split_surds`
  fast path.
- If all addends then have square-root depth `0`, `_sqrt_match(p)` returns the
  empty match list `[]`.
- For additive expressions made only from regular positive-rational square-root
  surds, the existing `split_surds` fast path remains available.

Frame condition: no public signature or return shape changes.

### `split_surds(expr)`

Domain: additive expression handled by the square-root rationalization helpers.

Contract:

- Only `Pow` terms with exponent `S.Half` count as square-root surds.
- If no such terms are present, return `(S.One, S.Zero, expr)`.
- If such terms are present, preserve the existing decomposition invariant:
  `expr == a*sqrt(g) + b`, where `g` is the selected gcd of the square-root
  radicands, `a` contains the terms sharing that factor, and `b` contains the
  remaining terms.

Frame condition: public return arity remains the same.

### `_split_gcd(*a)`

Domain: private helper over a tuple of surd squares.

Contract:

- For non-empty input, preserve the existing gcd partition behavior.
- For empty input, return `(S.One, [], [])` as a neutral split.

### `rad_rationalize(num, den)`

Domain: SymPy numerator and denominator.

Contract:

- If `den` is not additive, return `(num, den)`.
- If `den` is additive but `split_surds(den)` returns no square-root component
  (`a == 0`), return `(num, den)`.
- If `split_surds(den)` returns a square-root component (`a != 0`), perform the
  existing conjugate step and recurse on the transformed denominator.

Partial-correctness note: termination is proved only for the issue-supported
families: no-surd denominators stop immediately, and `sqrt(2)+I` performs one
square-root-removing step before stopping.

## Adequacy Summary

The spec is intent-derived for unsupported expressions returning unchanged and
for preserving valid square-root rationalization. The only implementation facts
used are branch structure and helper return shape. No ordered result or legacy
behavior is accepted without public evidence.

# Intent Spec

Status: constructed, not machine-checked.

## Public Intent

1. `Dagger(Operator) * IdentityOperator()` must simplify to the daggered
   operator expression itself. The issue shows the expected comparator:
   `A * Identity` gives `A`, while `Dagger(A) * Identity` incorrectly keeps the
   identity factor.

2. `IdentityOperator()` is a two-sided identity for quantum operators. The
   `IdentityOperator` docstring says it satisfies `op * I == I * op == op` for
   any operator `op`; an unevaluated dagger of an `Operator` is operator-valued
   for this purpose.

3. The simplification must be limited to quantum-operator targets. Existing
   public tests keep `I * x` as a generic `Mul` when `x` is a plain symbol, so
   non-operator operands must not be consumed by `IdentityOperator`.

4. Existing direct `Operator * IdentityOperator()` and
   `IdentityOperator() * Operator` behavior must be preserved.

## Domain

The audited domain is direct binary multiplication through the involved
`__mul__` methods:

- `Dagger.__mul__(self, other)` where `self == Dagger(A)` and `A` is an
  `Operator`;
- `IdentityOperator.__mul__(self, other)` where `other` is an `Operator` or
  `Dagger(Operator)`.

This spec does not claim global canonicalization for direct `Mul(...)`
construction or arbitrary composite operator expressions. That broader behavior
is not the behavior used in the issue example and would conflict with public
tests that preserve generic `Mul` results for non-operator products.

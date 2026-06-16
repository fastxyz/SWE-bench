# Proof Obligations

Status: constructed, not machine-checked.

| ID | Source Path | Precondition | Postcondition | Evidence |
|---|---|---|---|---|
| PO-DAGGER-RIGHT-ID | `Dagger.__mul__` | `self` is `Dagger(A)` and `A` is an `Operator`; `other` is `IdentityOperator(N)`. | Return `self`, i.e. `Dagger(A)`. | E1, E2 |
| PO-DAGGER-LEFT-ID | `IdentityOperator.__mul__` | `self` is `IdentityOperator(N)`; `other` is `Dagger(A)` and `A` is an `Operator`. | Return `other`, i.e. `Dagger(A)`. | E3 |
| PO-OP-RIGHT-ID | `Operator.__mul__` | `self` is `Operator(A)`; `other` is `IdentityOperator(N)`. | Return `self`, i.e. `A`. | E1, E4 |
| PO-OP-LEFT-ID | `IdentityOperator.__mul__` | `self` is `IdentityOperator(N)`; `other` is `Operator(A)`. | Return `other`, i.e. `A`. | E3, E4 |
| PO-DAGGER-NONOP-FRAME | `Dagger.__mul__` | `self` is `Dagger(X)` where `X` is not an `Operator`; `other` is `IdentityOperator(N)`. | Delegate to generic multiplication, represented as `Mul(Dagger(X), IdentityOperator(N))`. | E5, E6 |
| PO-NONOP-FRAME | `IdentityOperator.__mul__` | `self` is `IdentityOperator(N)`; `other` is not an operator-valued target. | Return generic `Mul(self, other)`. | E5 |

## Verification Conditions

VC1. `isinstance(other, IdentityOperator) and isinstance(self.args[0], Operator)`
is exactly the runtime discriminator for PO-DAGGER-RIGHT-ID.

VC2. If VC1 is false in `Dagger.__mul__`, control reaches `Expr.__mul__`, so the
special case cannot erase non-operator operands.

VC3. In `IdentityOperator.__mul__`, the original `isinstance(other, Operator)`
branch still proves PO-OP-LEFT-ID.

VC4. The added disjunct
`isinstance(other, Dagger) and isinstance(other.args[0], Operator)` proves
PO-DAGGER-LEFT-ID.

VC5. If both `IdentityOperator.__mul__` disjuncts are false, control reaches
`Mul(self, other)`, preserving PO-NONOP-FRAME.

There are no loops or recursive calls; partial and total correctness coincide
for these direct expression-construction methods, modulo Python method return.

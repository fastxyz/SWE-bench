# Public Evidence Ledger

Status: constructed, not machine-checked.

| ID | Source | Evidence | Semantic Obligation | Status |
|---|---|---|---|---|
| E1 | `benchmark/PROBLEM.md` | "`A * Identity #This gives A, correctly`" | Direct multiplication by `IdentityOperator` should remove the identity for an operator target. | Encoded in PO-OP-RIGHT-ID and used as comparison for PO-DAGGER-RIGHT-ID. |
| E2 | `benchmark/PROBLEM.md` | "`B = Dagger(A)`" followed by "`B * Identity #This returns A^\\dagger I`" | Direct `Dagger(Operator) * IdentityOperator()` should return `Dagger(Operator)`, not a product retaining the identity. | Encoded in PO-DAGGER-RIGHT-ID. |
| E3 | `repo/sympy/physics/quantum/operator.py` docstring | "`op * I == I * op == op for any operator op`" | The identity law is two-sided for operator-valued operands. | Encoded in PO-DAGGER-LEFT-ID and PO-OP-LEFT-ID. |
| E4 | `repo/sympy/physics/quantum/tests/test_operator.py` | `assert I * O == O`, `assert O * I == O` | Existing direct operator identity behavior must be preserved. | Encoded in PO-OP-LEFT-ID and PO-OP-RIGHT-ID. |
| E5 | `repo/sympy/physics/quantum/tests/test_operator.py` | `assert isinstance(I * x, Mul)` | `IdentityOperator` must not erase non-operator operands. | Encoded in PO-NONOP-FRAME. |
| E6 | `repo/sympy/physics/quantum/tests/test_dagger.py` | `assert Dagger(A).is_commutative is False` for a noncommutative symbol | `Dagger` can represent noncommutative non-operator objects, so the fix must distinguish `Dagger(Operator)` from other dagger expressions. | Encoded in PO-DAGGER-NONOP-FRAME. |

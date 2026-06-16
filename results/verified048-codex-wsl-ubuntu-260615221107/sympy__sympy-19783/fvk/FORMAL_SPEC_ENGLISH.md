# Formal Spec English

Status: constructed, not machine-checked.

1. PO-DAGGER-RIGHT-ID: For every quantum operator `A` and every identity
   operator dimension `N`, direct multiplication
   `Dagger(A) * IdentityOperator(N)` returns `Dagger(A)`.

2. PO-DAGGER-LEFT-ID: For every quantum operator `A` and every identity
   operator dimension `N`, direct multiplication
   `IdentityOperator(N) * Dagger(A)` returns `Dagger(A)`.

3. PO-OP-RIGHT-ID: For every quantum operator `A` and every identity operator
   dimension `N`, direct multiplication `A * IdentityOperator(N)` returns `A`.

4. PO-OP-LEFT-ID: For every quantum operator `A` and every identity operator
   dimension `N`, direct multiplication `IdentityOperator(N) * A` returns `A`.

5. PO-DAGGER-NONOP-FRAME: If the dagger expression wraps a non-operator, direct
   multiplication by `IdentityOperator(N)` remains a generic multiplication
   expression rather than being simplified as a quantum operator identity.

6. PO-NONOP-FRAME: If `IdentityOperator(N)` is multiplied directly by a
   non-operator expression, the result remains a generic multiplication
   expression.

There are no loops, recursive calls, mutation, or termination arguments in this
formal slice. Each claim is a direct single-step rewrite over expression shapes.

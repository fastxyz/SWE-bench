# Formal Spec English

Claim 1: If a determinant input matrix contains `S.NaN`, `det()` returns
`S.NaN` before dispatching to Bareiss, Berkowitz, or LU.

Claim 2: If Bareiss pivot scanning sees an expression that expands to exact
zero, it skips that candidate.

Claim 3: If a later candidate remains truthy after expansion, pivot scanning can
still return that later candidate with its original position.

Claim 4: If a candidate is non-expression and truthy, pivot scanning keeps the
old behavior and returns it.

Claim 5: No public determinant method signature or method-name normalization is
changed.


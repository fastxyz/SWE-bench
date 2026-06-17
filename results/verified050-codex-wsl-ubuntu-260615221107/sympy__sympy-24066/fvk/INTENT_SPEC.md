# Intent Specification

Status: intent-only, based on public issue text, public source, and public tests.

1. The collector must recognize that `second/(ohm*farad)` is dimensionless under
   SI because the SI dimension system proves it.
2. `exp(second/(ohm*farad))` must collect as dimensionless, specifically with
   dimension `Dimension(1)`.
3. `100 + exp(second/(ohm*farad))` must not raise the reported dimension mismatch.
4. Additions of non-equivalent dimensions must still raise `ValueError`.
5. The fix must not make `_collect_factor_and_dimension()` strictly reject every
   function with a dimensionful argument, because existing public behavior
   preserves dimensions for such functions in some paths.
6. New equivalence or dimensionless checks introduced by the fix must be
   conservative: failure to analyze a dimension expression is not proof of
   dimensionlessness or equivalence.

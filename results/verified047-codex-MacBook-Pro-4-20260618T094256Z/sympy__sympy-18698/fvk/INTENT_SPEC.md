# Intent Spec

Status: constructed, not machine-checked.

## Public Intent

1. `sqf_list()` on expression inputs must be consistent with `Poly(...).sqf_list()`
   for the reported univariate behavior: factors with the same multiplicity are
   returned as one product for that multiplicity.

2. The concrete reported family includes the multiplicity-3 pair `(x - 3)` and
   `(x - 2)`, which should become `x**2 - 5*x + 6` with exponent `3`.

3. The same grouping principle applies to any equal multiplicity in a
   univariate square-free decomposition, not only exponent `3`.

4. The fix is a post-processing step on the generic square-free factor list.
   It should not change ordinary `factor_list()` behavior.

5. Multiple-generator behavior is public-issue ambiguous. The in-repo public
   test for `sqf_list(x*(x + y))` is treated as a compatibility frame for this
   V1 audit, so the proof does not require combining factors whose generator
   tuples differ.

6. Existing coefficient handling, fraction handling, sorting, and `polys`
   output conversion are outside the reported defect and should be framed as
   unchanged by this fix.

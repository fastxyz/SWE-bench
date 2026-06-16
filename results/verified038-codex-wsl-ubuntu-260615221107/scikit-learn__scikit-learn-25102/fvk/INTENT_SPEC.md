# Intent Spec

Status: constructed, not machine-checked.

## Required Behavior From Public Intent

1. For feature selectors that export the same input features or a subset of input features, pandas output should preserve the semantic pandas metadata of the selected original columns where this can be done without casting computed values.

2. `SelectKBest` is explicitly in scope. The public hint states that feature selection can compute selected features using NumPy but then select the columns on the original container before conversion.

3. The concrete motivating case is a pandas `DataFrame` with heterogeneous dtypes, including `float16` and `category`, transformed with `set_output(transform="pandas")`. The selected output columns should retain the selected input columns' dtype metadata instead of becoming homogeneous `float64`.

4. The dtype-preserving behavior is not a global `set_output` cast-back rule. The public discussion rejects generic cast-back because conversion can be lossy and misleading for transformers that compute new values.

5. Existing selector behavior outside the pandas-output/DataFrame/subset case remains in scope: validation must still occur, default output must remain array-like, sparse and dense array output must keep existing selection behavior, and empty selections must keep the existing warning and shape behavior.

6. The `set_output` wrapper remains responsible for final pandas container wrapping, feature names, and index handling when a transform returns an array. If a selector can return an already-sliced `DataFrame`, the wrapper may still adjust columns and index according to the existing API.

7. Public API compatibility is required: no public method signature should change, and subclasses of `SelectorMixin` should not need to implement a new method to keep working.

## Out Of Scope

1. Generic preservation for transformers that compute new values, such as scalers, imputers, encoders, or other transformers whose output is not a direct subset of input columns.

2. Memory-use preservation. The public discussion states that the issue is semantic information, not avoiding internal allocation.

3. Test deletion. This task forbids editing tests, and the proof is constructed only.

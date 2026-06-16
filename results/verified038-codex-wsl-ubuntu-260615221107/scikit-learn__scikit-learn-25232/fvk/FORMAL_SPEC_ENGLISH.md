# Formal Spec English

Status: constructed for FVK audit; not machine-checked.

This file paraphrases the nontrivial K claims in
`fvk/iterative-imputer-spec.k`.

## Claims

C-001. `initIterative(F) => iterativeObj(F)`

For any fill value `F`, constructing the abstract `IterativeImputer` stores
exactly `F` as the estimator's fill value.

C-002. `makeInitialImputer(S, F) => simpleObj(S, F)`

For any allowed initialization strategy `S` and fill value `F`, the internal
initial imputer receives exactly those two values.

C-003. `validMask(constant, N, constantStats(N, NaNFill)) => allIndices(N)`

For any non-negative feature count `N`, if the initial strategy is constant and
the internal statistics are all `NaNFill`, all features remain valid. This is
the formal `np.nan fill_value` obligation.

C-004. `validMask(constant, N, STATS) => allIndices(N)`

For any non-negative feature count `N`, constant initial strategy does not use
`NaN` statistics as the invalid-feature marker. It keeps all feature indices.

C-005. Non-constant `validMask` claims

For `mean`, `median`, and `most_frequent`, the validity mask is still the list
of non-NaN statistic indices. This is the frame condition preserving existing
non-constant behavior.

C-006. `initIterative(NoneFill)` and
`makeInitialImputer(constant, NoneFill)`

The default `fill_value=None` is stored and forwarded unchanged. The default
constant remains the responsibility of `SimpleImputer`.


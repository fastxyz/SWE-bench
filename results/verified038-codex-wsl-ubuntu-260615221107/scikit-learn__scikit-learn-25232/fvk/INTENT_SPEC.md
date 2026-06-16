# Intent Spec

Status: constructed for FVK audit; not machine-checked.

## Scope

This FVK pass audits the V1 repair for the public issue
`scikit-learn__scikit-learn-25232`. The audited production code is the
affected public API and initialization path in
`repo/sklearn/impute/_iterative.py`:

- `IterativeImputer.__init__`
- the internal `SimpleImputer` construction in `_initial_imputation`
- the feature-validity decision immediately after initial imputation

The proof does not attempt to verify the entire chained imputation algorithm,
estimator convergence, or estimator-specific support for missing values.

## Intent-Derived Obligations

I-001. `IterativeImputer` must expose a public `fill_value` parameter.

Evidence: the issue title and proposed solution say `IterativeImputer` has no
parameter `fill_value`, and that the parameter needs to be added when
`initial_strategy` is `"constant"`.

I-002. `fill_value` must control the constant passed to the first imputation
round.

Evidence: the issue describes the first imputation round and quotes
`SimpleImputer.fill_value` as the mechanism used when
`strategy == "constant"`.

I-003. The default behavior must remain compatible with the previous API.

Evidence: the issue asks for an added parameter, not a changed default. Existing
`SimpleImputer` behavior uses `fill_value=None` to select its default constant.

I-004. `np.nan` must be accepted as `fill_value` at the `IterativeImputer` API
level for users whose estimator supports missing values.

Evidence: the issue explicitly says to allow `np.nan` as `fill_value` for
compatibility with decision tree-based estimators.

I-005. The new parameter must not alter non-constant initial strategies.

Evidence: `fill_value` is meaningful only for the constant strategy in the
quoted `SimpleImputer` docs. The public request is scoped to
`initial_strategy="constant"`.

I-006. Passing a `SimpleImputer` instance as `initial_strategy` is not required
by this repair.

Evidence: the issue discussion mentions that capability as a suggestion "to be
implemented" later, while the concrete proposed solution is to add
`fill_value`.

## Default-Domain Assumptions

D-001. `fill_value` is treated as an arbitrary Python object at parameter
validation time, matching `SimpleImputer`'s `"no_validation"` parameter
constraint. Type compatibility for numerical data remains delegated to
`SimpleImputer`.

D-002. If a downstream estimator cannot fit or predict with `np.nan`, that is
outside this repair. The public issue asks only that `IterativeImputer` allows
the value for estimators that do support it.


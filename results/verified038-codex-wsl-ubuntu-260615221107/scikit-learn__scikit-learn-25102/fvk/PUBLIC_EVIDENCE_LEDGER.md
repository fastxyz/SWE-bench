# Public Evidence Ledger

Status: constructed, not machine-checked.

## E1: Reported Bug

- Source: `benchmark/PROBLEM.md`
- Evidence: "The ouput shows that both the `category` and `np.float16` are converted to `np.float64` in the dataframe output."
- Obligation: pandas output from the reported selector workflow must not erase dtype metadata for selected original DataFrame columns.
- Spec status: encoded in `PO-DF-DTYPE-PRESERVE` and `SELECTOR-PANDAS-PRESERVE`.

## E2: Semantic Motivation

- Source: `benchmark/PROBLEM.md`
- Evidence: "Dtypes can contain information relevant for later steps of the analyses."
- Obligation: dtype preservation is a semantic frame condition, like preserving feature names and index, not only a numeric representation concern.
- Spec status: encoded in the DataFrame model as `dtypes(selectDf(X, M)) == selectDTypes(dtypes(X), M)`.

## E3: Concrete Example

- Source: `benchmark/PROBLEM.md`
- Evidence: the example uses `SelectKBest(chi2, k=2)`, `selector.set_output(transform="pandas")`, and a `DataFrame` containing `float16` and `category` columns.
- Obligation: `SelectKBest` is in the required selector family; `fit_transform` and `transform` must both reach the same dtype-preserving selector transform path.
- Spec status: encoded through `SelectorMixin.transform`; `fit_transform` is covered because `TransformerMixin.fit_transform` delegates to `transform`.

## E4: Scope Limitation From Public Hint

- Source: `benchmark/PROBLEM.md`
- Evidence: "For estimators such as `SelectKBest` we can probably do it with little added complexity."
- Obligation: a targeted selector fix is justified.
- Spec status: encoded as `SelectorMixin` scope, not a generic `_SetOutputMixin` cast-back change.

## E5: Rejected Generic Cast-Back

- Source: `benchmark/PROBLEM.md`
- Evidence: concerns that converting to one dtype internally and then casting back "loses information or leads to other weirdness" and can be a "lie".
- Obligation: do not implement dtype preservation by casting computed arrays back to original dtypes.
- Spec status: encoded as a finding rejecting generic cast-back and as the `selectDf(original, mask)` postcondition.

## E6: Existing API Contract

- Source: `repo/sklearn/feature_selection/_base.py`
- Evidence: `SelectorMixin.transform` says "Reduce X to the selected features" and `_transform` returns only selected columns.
- Obligation: selectors are pass-through subset transformers; using the original container for selected columns is behaviorally aligned with the API.
- Spec status: encoded in all selector claims.

## E7: Existing `set_output` Contract

- Source: `repo/sklearn/utils/_set_output.py`
- Evidence: `_wrap_data_with_container` wraps transform output only when dense output config is `"pandas"` and auto wrapping is configured.
- Obligation: dtype preservation must respect the existing output configuration and must not force pandas output when default output is configured.
- Spec status: encoded in `PO-DEFAULT-UNCHANGED` and `SELECTOR-DEFAULT-ARRAY`.

## E8: Existing `ColumnTransformer` Mixed Dtype Behavior

- Source: `repo/sklearn/compose/tests/test_column_transformer.py`
- Evidence: existing tests assert mixed pandas dtypes are preserved for passthrough remainder under pandas output.
- Obligation: preserving dtype metadata for pass-through DataFrame columns is consistent with established pandas-output semantics.
- Spec status: supporting evidence for selector pass-through behavior; not used to broaden scope to computed transformers.

## E9: Compatibility Evidence

- Source: `repo/sklearn/feature_selection/_base.py` and public subclasses in `repo/sklearn/feature_selection/`
- Evidence: subclasses implement `_get_support_mask`; `SelectorMixin.transform` supplies shared transform behavior.
- Obligation: no new subclass override or public signature change should be required.
- Spec status: encoded in `PUBLIC_COMPATIBILITY_AUDIT.md`.

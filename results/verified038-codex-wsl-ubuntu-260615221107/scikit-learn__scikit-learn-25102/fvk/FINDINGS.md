# FVK Findings

Status: constructed, not machine-checked.

## F1: V1 Correctly Localized The Main Bug

- Classification: resolved code bug.
- Evidence: `SelectorMixin.transform` validated pandas input into a homogeneous array before selecting columns; `set_output` then wrapped that array into a `DataFrame`.
- Input -> observed vs expected: mixed-dtype pandas `DataFrame` with `SelectKBest(...).set_output(transform="pandas")` -> observed legacy behavior converted selected `category` and `float16` columns to `float64`; expected selected original columns preserve `category` and `float16`.
- Resolution: V1 selected from the original `DataFrame` under pandas output. V2 keeps that behavior.
- Proof obligations: `PO-DF-DTYPE-PRESERVE`, `PO-WRAPPER-FRAME`.

## F2: V1 Read Output Configuration Before Validation

- Classification: compatibility risk; fixed in V2.
- Evidence: V1 called `_get_output_config("transform", self)` at the top of raw `SelectorMixin.transform`.
- Input -> observed vs expected: invalid output config combined with invalid input -> V1 could report output-config failure before validation; expected behavior is closer to the existing wrapper protocol, where raw transform validation and selection happen before `_wrap_data_with_container` reports output-config errors.
- Resolution: V2 stores the original DataFrame before validation but calls `_is_pandas_output_configured` only after `_validate_data` succeeds. That helper treats invalid output config as not pandas-preserving so the existing wrapper remains responsible for reporting invalid output config when raw transform succeeds.
- Proof obligations: `PO-VALIDATE-FIRST`, `PO-INVALID-CONFIG-ORDER`.

## F3: Generic Cast-Back Remains Rejected

- Classification: rejected alternative.
- Evidence: public discussion warns that converting values to a homogeneous dtype and casting back may lose information and misrepresent computations.
- Input -> observed vs expected: transformer that computes new float64 values from mixed input -> generic cast-back would report original dtypes even though output values were computed in a different dtype; expected no generic dtype-preservation claim.
- Resolution: no change to `_SetOutputMixin` or `_wrap_in_pandas_container`.
- Proof obligations: `PO-SCOPE-LIMIT`.

## F4: Empty Selection Boundary Remains Covered

- Classification: boundary behavior confirmed.
- Evidence: `_transform` has an existing all-false-mask branch that warns and returns zero selected features.
- Input -> observed vs expected: pandas `DataFrame` with pandas output and no selected features -> expected zero-column pandas output with input index after wrapper processing; array/sparse/default paths keep existing empty-array behavior.
- Resolution: V2 returns `_safe_indexing(X, safe_mask(X, mask), axis=1)` for DataFrame empty selections and preserves the existing array branch for non-DataFrame paths.
- Proof obligations: `PO-EMPTY-PANDAS`, `PO-EMPTY-ARRAY`.

## F5: No Public API Compatibility Finding Remains Open

- Classification: compatibility confirmed by static audit.
- Evidence: public selector subclasses keep the same `_get_support_mask` contract and `transform(self, X)` signature.
- Input -> observed vs expected: any existing subclass of `SelectorMixin` -> expected no new override or parameter; observed V2 adds only a private helper and shared transform behavior.
- Resolution: no further code change required.
- Proof obligations: `PO-PUBLIC-COMPAT`.

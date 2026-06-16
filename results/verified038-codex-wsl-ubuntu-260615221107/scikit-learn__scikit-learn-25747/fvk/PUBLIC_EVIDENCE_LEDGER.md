# Public Evidence Ledger

## E1: Bug Symptom

- Source: `benchmark/PROBLEM.md`
- Evidence: "FeatureUnion not working when aggregating data and pandas transform
  output selected" and "Expected Results: No error is thrown when using
  `pandas` transform output."
- Obligation: pandas output wrapping must not raise the reported length mismatch
  for aggregated FeatureUnion results.
- Status: encoded by `set-output-spec.k` claim 1 and `PROOF_OBLIGATIONS.md`
  PO-1.

## E2: Reported Failure Mechanism

- Source: `benchmark/PROBLEM.md`
- Evidence: traceback enters `_wrap_in_pandas_container` and fails at
  `data_to_wrap.index = index` with "Expected axis has 4 elements, new values
  have 96 elements".
- Obligation: the wrapper must not assign the original input index to an
  existing output `DataFrame` when the lengths differ.
- Status: encoded by PO-1 and PO-2.

## E3: Public Hint

- Source: `benchmark/PROBLEM.md`
- Evidence: "In principle, we can have a less restrictive requirement and only
  set the index if it is not defined."
- Obligation: use the provided/original index only for outputs that do not
  already define a pandas `DataFrame` index.
- Status: encoded by PO-1, PO-2, and PO-3.

## E4: Existing DataFrame Index

- Source: `benchmark/PROBLEM.md`
- Evidence: "If transformer returned a `DataFrame` this already has some kind
  of index. Why should we restore the original input index?"
- Obligation: preserve existing `DataFrame` index identity through wrapping.
- Status: encoded by PO-1 and PO-2.

## E5: Column Naming API

- Source: `repo/doc/developers/develop.rst`
- Evidence: the `set_output` API is defined when a transformer defines
  `get_feature_names_out`; `get_feature_names_out` is used to get pandas output
  column names.
- Obligation: the fix must not remove column-name wrapping for existing
  `DataFrame` output.
- Status: encoded by PO-2.

## E6: Sparse Guard

- Source: `repo/sklearn/utils/_set_output.py`
- Evidence: `_wrap_in_pandas_container` raises `ValueError("Pandas output does
  not support sparse data.")`.
- Obligation: sparse behavior is unchanged by the index fix.
- Status: encoded by PO-4.

## E7: Suspect Legacy Test

- Source: `repo/sklearn/utils/tests/test_set_output.py`
- Evidence: `test__wrap_in_pandas_container_dense_update_columns_and_index`
  expected `_wrap_in_pandas_container` to override an existing DataFrame index.
- Obligation: classify as suspect legacy evidence because it encodes the behavior
  the public issue identifies as too restrictive. Do not use it to veto E2-E4.
- Status: recorded in `FINDINGS.md` F2. Tests were not edited.

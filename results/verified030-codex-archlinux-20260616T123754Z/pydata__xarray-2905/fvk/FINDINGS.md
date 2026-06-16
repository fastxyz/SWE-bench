# FVK Findings

Status: source and proof-construction audit only; no tests, Python, or K tooling
were run.

## F1 - Pre-V1 arbitrary `.values` assignment bug

- Classification: code bug in the baseline behavior, fixed by V1.
- Public evidence: E1-E7.
- Input: object-dtype scalar assignment,
  `bad_indexed.loc[{'dim_0': 0}] = HasValues()` where `HasValues.values == 5`.
- Pre-V1 observed behavior from the issue: destination contains `array(5)`.
- Expected behavior: destination contains the original `HasValues` object.
- Mechanism: the old `getattr(data, "values", data)` made an arbitrary object
  indistinguishable from intended xarray/pandas containers.
- V1 audit result: fixed. The explicit type check excludes arbitrary `.values`
  objects, so the modeled path reaches `objectArray(arbitraryValuesObject(...))`.
- Proof obligations: PO1, PO2.

## F2 - Scalar `DataArray(..., dims=[])` construction had the same coercion bug

- Classification: code bug in the baseline behavior, fixed by V1.
- Public evidence: E8-E9.
- Input: `DataArray(HasValues, dims=[])` or an equivalent scalar object with a
  `.values` attribute.
- Pre-V1 observed behavior from the issue: `array(5)`.
- Expected behavior: scalar object data containing `HasValues`.
- Mechanism: `DataArray.__init__` also calls `as_compatible_data`, so the same
  generic `.values` probe affected construction.
- V1 audit result: fixed by the same helper-level change.
- Proof obligations: PO1, PO3.

## F3 - Known container compatibility frame condition

- Classification: compatibility risk audited; no remaining code bug found.
- Public evidence: E9-E13.
- Input classes: `xarray.DataArray`, `xarray.Variable`, `pandas.Series`,
  `pandas.DataFrame`, `pdcompat.Panel`, `pandas.Index`, and supported adapter
  arrays.
- Expected behavior: known self-described containers remain intentionally
  unwrapped or wrapped through their existing special branches.
- V1 audit result: satisfied. `Series`, `DataFrame`, `Panel`, and `DataArray`
  are explicitly unwrapped; `Variable`, `pandas.Index`, and supported adapter
  arrays continue to hit earlier branches.
- Proof obligations: PO4, PO5, PO7.

## F4 - Proof capability and execution boundary

- Classification: proof capability gap, not a code bug.
- Evidence: FVK MVP instructions and the no-execution task constraint.
- Boundary: the K artifact models the relevant dispatch and object-vs-payload
  observable, but it abstracts full NumPy/pandas conversion internals.
- Consequence: the proof is constructed, not machine-checked. Test removal is
  not recommended unless the emitted K commands and the real project tests are
  run in an appropriate environment.
- Proof obligations: PO8.

## F5 - Test gap to cover after this benchmark phase

- Classification: test gap, not actionable here because test edits are
  forbidden.
- Recommended tests: scalar object assignment with an arbitrary `.values`
  property; scalar `DataArray(..., dims=[])` construction with the same object;
  frame tests for `Series`, `DataFrame`, `DataArray`, and `pd.Index` behavior.
- Proof obligations: PO8.

## Summary

No unresolved code finding justifies changing V1. The remaining findings are the
honesty boundary for unexecuted proofs/tests and suggested future tests.

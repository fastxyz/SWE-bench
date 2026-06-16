# Iteration Guidance

Status: V1 is confirmed; no V2 production-code edit is required.

## Decision

Keep V1 unchanged. The FVK obligations in `fvk/PROOF_OBLIGATIONS.md` are
discharged by the current source, and `fvk/FINDINGS.md` has no open production
bug.

## Why no source edit

- F1/O1: `_RepeatedSplits.__repr__` exists and delegates to `_build_repr`.
- F2/O3/O5/O6: `_build_repr` now recovers `n_splits` from `cvargs`.
- F4/O7: direct attributes still take precedence, preserving existing splitter
  repr behavior.
- F3/O5: parameter order remains the project convention from `_pprint`, which
  is supported by public source tests and the public hint.

## Suggested future tests

Do not edit tests in this benchmark pass. In a normal development setting, add
repr regression coverage for:

- `repr(RepeatedKFold())`
- `repr(RepeatedStratifiedKFold())`
- non-default `n_splits`, `n_repeats`, and `random_state`
- a guard against `n_splits=None` when the value is present in `cvargs`

## Machine-check follow-up

Run the commands in `fvk/PROOF.md` in an environment with K installed before
treating proof-based test-removal recommendations as actionable.


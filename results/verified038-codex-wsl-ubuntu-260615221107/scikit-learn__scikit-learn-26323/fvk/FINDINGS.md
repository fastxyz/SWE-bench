# FVK Findings

Status: constructed, not machine-checked. No tests or code were run.

## F-001: V1 Fixed The Reported Remainder Propagation Gap

- Classification: code bug addressed by V1.
- Evidence: E1, E2, PO-1, PO-2, PO-3.
- Input: a `ColumnTransformer` with one explicit boolean selector transformer,
  `remainder=VarianceThreshold()`, and pre-fit
  `set_output(transform="pandas")`.
- Observed before V1: explicit child was pandas-configured but the remainder
  estimator clone was default-configured, so dense `_hstack` could not use the
  all-pandas branch.
- Expected: estimator-valued `remainder` receives the same output config as
  explicit transformers, and the later clone participates in pandas stacking.
- Resolution: V1 added `_safe_set_output(self.remainder, transform=transform)`
  for non-sentinel remainders in `ColumnTransformer.set_output`.

## F-002: V1 Widened A Pre-Existing `transform=None` Helper Edge

- Classification: code bug addressed by V2.
- Evidence: E8, PO-4.
- Input: `_safe_set_output(estimator_without_set_output_but_with_transform,
  transform=None)`, now reachable through the new remainder propagation path.
- Observed in V1: the helper could still check for child `set_output` and raise,
  despite the documented no-op behavior for `transform=None`.
- Expected: `transform=None` leaves configuration unchanged and does not require
  child `set_output`.
- Resolution: V2 adds an early `if transform is None: return estimator` to
  `_safe_set_output`.

## F-003: Non-`None` Unconfigurable Transformer Error Must Stay

- Classification: compatibility obligation, confirmed.
- Evidence: E9, PO-5.
- Input: `_safe_set_output(estimator_without_set_output_but_with_transform,
  transform="pandas")`.
- Expected: keep raising `ValueError("Unable to configure output...")`.
- Resolution: V2 preserves this behavior because the early return applies only
  to `transform is None`.

## Residual Risks

- The proof is constructed but not machine-checked with K.
- No tests, Python imports, or K tooling were run in this environment.
- The formal model proves the output-container discriminator, not full pandas
  dtype implementation internals.

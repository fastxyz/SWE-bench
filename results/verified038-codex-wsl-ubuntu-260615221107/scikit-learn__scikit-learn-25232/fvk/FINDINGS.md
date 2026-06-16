# FVK Findings

Status: constructed for FVK audit; not machine-checked.

## Summary

The FVK audit confirms V1 within the specified bug-fix scope. No additional
production-code change is justified by the public intent and proof obligations.

## Findings

F-001 - Original API gap is closed.

- Evidence: E-001 and O-001.
- Pre-V1 observed behavior: `IterativeImputer(fill_value=...)` was not a valid
  public constructor path.
- Expected behavior: `fill_value` is a public estimator parameter with default
  `None`.
- V1 status: fixed. The constructor accepts `fill_value`, stores
  `self.fill_value`, documents it, and includes it in parameter constraints.

F-002 - Original forwarding gap is closed.

- Evidence: E-002, E-003, O-002, O-005.
- Pre-V1 observed behavior: `_initial_imputation` constructed
  `SimpleImputer(...)` without `fill_value`, so the user could not control the
  initial constant.
- Expected behavior: the internal `SimpleImputer` receives the user's
  `fill_value`, including `None` for default behavior.
- V1 status: fixed. `fill_value=self.fill_value` is forwarded.

F-003 - `np.nan` constant no longer becomes an invalid-feature marker.

- Evidence: E-005, O-003, O-004.
- Pre-V1 risk under a naive forwarding-only fix: `SimpleImputer` would store
  `np.nan` in `statistics_`, and the old `np.isnan(statistics_)` validity rule
  would map every feature to invalid.
- Expected behavior: when `initial_strategy="constant"`, a `np.nan`
  fill value is intentional and all feature indices remain valid for the
  iterative estimator path.
- V1 status: fixed. The constant strategy uses `np.arange(X.shape[1])` for
  `valid_mask`.

F-004 - Non-constant strategies remain framed.

- Evidence: I-005 and O-004.
- Observed behavior in V1: `mean`, `median`, and `most_frequent` still use the
  non-NaN statistics filter.
- Expected behavior: adding `fill_value` should not change non-constant
  strategies.
- V1 status: confirmed.

F-005 - Residual proof coverage is intentionally limited.

- Evidence: SPEC_AUDIT coverage limits and PROOF_OBLIGATIONS residual risks.
- Observed limitation: this FVK pass does not prove full chained-imputation
  numerical correctness, convergence, sparse behavior, all-empty target
  handling, or the chosen estimator's support for `np.nan`.
- Expected handling: keep those outside the V1 confirmation unless a separate
  public intent entry requires them.
- V1 status: no code change. The issue only requires the public parameter,
  forwarding, default preservation, and `np.nan` admission.

## Proof-Derived Findings From `/verify`

No failed VC or adequacy mismatch was found in the scoped formal model. The
constructed proof remains conditioned on future machine checking with the
commands listed in `fvk/PROOF.md`.


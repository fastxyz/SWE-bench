# FVK Proof Obligations

Status: constructed, not machine-checked.

## O-001: Resolved Auto-OvR Branch Selects OvR Indexing

- Public evidence: E-001, E-002, E-004.
- Precondition: `multi_class` may be `'auto'`; the effective strategy returned
  by `_check_multi_class` is OvR because the problem is binary or the solver is
  `liblinear`; the class-specific `coefs_paths` value has OvR rank
  `(fold, candidate, coefficient)`.
- Obligation: the no-refit block must use the OvR selection
  `coefs_paths[i, best_indices[i], :]` for every fold `i`.
- V2 discharge: the branch condition is `if multi_class == 'ovr'`, where
  `multi_class` is the resolved local value.
- Failure mode if absent: `coefs_paths[:, i, best_indices[i], :]` over-indexes
  the 3D OvR path, matching the reported `IndexError`.

## O-002: Resolved Multinomial Branch Selects Multinomial Indexing

- Public evidence: E-004, E-005.
- Precondition: the effective strategy is multinomial; `coefs_paths` retains
  multinomial rank `(class, fold, candidate, coefficient)`.
- Obligation: the no-refit block must use the multinomial selection
  `coefs_paths[:, i, best_indices[i], :]`.
- V2 discharge: the `else` branch is reached only when the resolved
  `multi_class` is not OvR, which after `_check_multi_class` means
  multinomial.

## O-003: Best-Fold C Selection Is Preserved

- Public evidence: E-005.
- Precondition: `best_indices = argmax(scores, axis=1)` gives one candidate
  index per fold, and the candidate axis is ordered by l1-ratio blocks of
  length `len(Cs_)`.
- Obligation: selected C values are `Cs_[best_indices % len(Cs_)]`, and `C_`
  records their mean.
- V2 discharge: V2 does not alter this code path.

## O-004: Non-Elastic-Net l1_ratio_ Is Absent, Not Averaged

- Public evidence: E-003, E-006, E-007.
- Precondition: active `penalty` is not `elasticnet`; local `l1_ratios_` is
  `[None]`.
- Obligation: no vector indexing or mean is attempted on `[None]`; the fitted
  estimator records `None` for the class's `l1_ratio_`.
- V2 discharge: the no-refit block computes an l1-ratio mean only when
  `self.penalty == 'elasticnet'`, otherwise appending `None`.

## O-005: Elastic-Net Attribute Shape Dimension Is Controlled by Active Penalty

- Public evidence: E-006, E-008.
- Precondition: fitting reaches the final attribute-normalization block.
- Obligation: `coefs_paths_`, `scores_`, and `n_iter_` receive an l1-ratio
  axis exactly when the active penalty is elastic-net.
- V2 discharge: the final reshape guard is `if self.penalty == 'elasticnet'`.

## O-006: Public API and Constructor State Are Preserved

- Public evidence: E-004, E-006, E-009.
- Precondition: callers instantiate `LogisticRegressionCV` using existing
  public parameters.
- Obligation: the patch must not change method signatures, constructor
  parameters, or stored constructor values used by `get_params`/cloning.
- V2 discharge: only internal branch guards and selections changed; no public
  signature or parameter storage changed.

## Claim Mapping

- `fvk/logregcv-refit-false-spec.k` claim `AUTO-OVR-NO-INDEX-ERROR` maps to
  O-001.
- `MULTINOMIAL-INDEX-OK` maps to O-002.
- `NON-ELASTICNET-L1-ABSENT` maps to O-004.
- `ELASTICNET-L1-MEAN-OK` maps to O-004 for the elastic-net side.
- `SHAPE-PLAIN-WHEN-NON-ELASTICNET` and
  `SHAPE-ELASTICNET-WHEN-ELASTICNET` map to O-005.
- `API-FRAME` is represented as a frame condition in `SPEC.md` and
  `PUBLIC_COMPATIBILITY_AUDIT.md`; it is not a runtime K transition.

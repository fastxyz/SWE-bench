# FVK Proof Obligations

Status: constructed, not machine-checked. These obligations are the checklist
used to decide whether V1 can stand.

## PO-001: Constructor Accepts and Stores the New Flag

- Public intent: INT-001, INT-004.
- Source evidence: `RidgeClassifierCV.__init__` includes
  `store_cv_values=False`; the `super(...).__init__` call passes
  `store_cv_values=store_cv_values`; `_BaseRidgeCV.__init__` assigns
  `self.store_cv_values = store_cv_values`.
- Formal claim: CLAIM-CONSTRUCT in `ridge-classifier-cv-spec.k`.
- Proof obligation: for every boolean `STORE`, constructing the estimator
  reaches object state `self.store_cv_values == STORE` and not an
  unexpected-keyword error.
- Disposition: discharged by source inspection and the constructed K claim.

## PO-002: fit Stores cv_values_ When store_cv_values=True and cv=None

- Public intent: INT-002.
- Source evidence: `RidgeClassifierCV.fit` calls `_BaseRidgeCV.fit(self, X, Y,
  sample_weight=sample_weight)`; `_BaseRidgeCV.fit` constructs `_RidgeGCV(...,
  store_cv_values=self.store_cv_values)` when `self.cv is None`; after
  `estimator.fit`, it copies `self.cv_values_ = estimator.cv_values_` when
  `self.store_cv_values`.
- Formal claim: CLAIM-FIT-STORE.
- Preconditions: existing `RidgeClassifierCV.fit` input validation accepts
  `X` and `y`; existing `_RidgeGCV.fit` returns normally.
- Proof obligation: on the in-domain path `store_cv_values=True` and `cv=None`,
  fitted `RidgeClassifierCV` exposes `cv_values_`.
- Disposition: discharged for the flag-propagation slice; numerical GCV
  correctness is outside the changed behavior.

## PO-003: cv != None Incompatibility is Preserved

- Public intent: INT-003.
- Source evidence: `_BaseRidgeCV.fit` raises `ValueError("cv!=None and
  store_cv_values=True are incompatible")` when `self.cv is not None` and
  `self.store_cv_values` is true.
- Formal claim: CLAIM-FIT-INCOMPATIBLE-CV.
- Proof obligation: the new public flag must not bypass the existing
  incompatibility guard.
- Disposition: discharged by unchanged base-class control flow.

## PO-004: scikit-learn Estimator Compatibility

- Public intent: INT-004, INT-005.
- Source evidence: `BaseEstimator._get_param_names` inspects explicit
  constructor parameters; `get_params` calls `getattr(self, key, None)`.
- Proof obligation: `store_cv_values` must be explicit in the constructor and
  must exist as an attribute after construction.
- Disposition: discharged because the parameter is explicit and the base
  initializer assigns the attribute.

## PO-005: No Unjustified Source Expansion

- Public intent: EV-001 through EV-004 concern constructor acceptance and
  cv-values storage, not numerical ridge behavior.
- Proof obligation: avoid adding classifier-specific storage or numerical logic
  when the existing base implementation already satisfies the public intent.
- Disposition: discharged by F-003. V1 should stand unchanged unless a future
  public requirement names a behavior not covered by `_BaseRidgeCV`.

## Machine-check commands, not executed

The task forbids K tooling. These are the commands that would be used later:

```sh
cd fvk
kompile mini-python.k --backend haskell
kast --backend haskell ridge-classifier-cv-spec.k
kprove ridge-classifier-cv-spec.k
```

Expected machine-check result if the mini semantics and claims are accepted:
`#Top` for all four claims.

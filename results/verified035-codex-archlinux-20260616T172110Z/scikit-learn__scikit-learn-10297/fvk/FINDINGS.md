# FVK Findings

Status: constructed, not machine-checked. Findings are based on public issue
text, source inspection, and formal proof obligations only.

## F-001: V1 resolves the reported constructor rejection

- Input: `RidgeClassifierCV(store_cv_values=True)`.
- Pre-V1 observed behavior from the issue: `TypeError: __init__() got an
  unexpected keyword argument 'store_cv_values'`.
- Expected behavior from EV-001 and EV-002: constructor accepts the documented
  flag.
- V1 source evidence: `RidgeClassifierCV.__init__` now includes
  `store_cv_values=False` and passes it to `_BaseRidgeCV.__init__`.
- Related proof obligations: PO-001, PO-004.
- Classification: code bug fixed by V1.
- Status: resolved; no additional source edit required.

## F-002: V1 preserves public constructor compatibility

- Input: existing calls such as `RidgeClassifierCV(class_weight=...)` or
  positional calls using arguments up to `class_weight`.
- Expected behavior from INT-004 and INT-005: prior argument meanings remain
  stable while the new parameter is discoverable.
- V1 source evidence: `store_cv_values` was appended after `class_weight`;
  no in-repo subclass override or public callsite conflict was found.
- Related proof obligations: PO-004.
- Classification: compatibility audit finding.
- Status: pass; no source edit required.

## F-003: No classifier-specific cv_values_ implementation is needed

- Input: valid `fit(X, y)` with `store_cv_values=True` and `cv=None`, assuming
  the existing classifier and GCV preconditions hold.
- Expected behavior from EV-003 and EV-004: fitted estimator has `cv_values_`.
- V1 source evidence: `RidgeClassifierCV.fit` converts `y` to the response
  matrix `Y` and calls `_BaseRidgeCV.fit`; `_BaseRidgeCV.fit` already forwards
  `store_cv_values` to `_RidgeGCV` and copies `estimator.cv_values_`.
- Related proof obligations: PO-002.
- Classification: implementation reuse confirmed.
- Status: pass; no duplicate storage code should be added.

## F-004: Proof scope excludes numerical GCV correctness and termination

- Input: arbitrary numeric `X`, `y`, and `alphas` accepted by existing
  `_RidgeGCV.fit`.
- Expected behavior for this issue: the flag controls whether `cv_values_` is
  stored; the issue does not request changing alpha selection or prediction
  values.
- Audit result: the constructed proof abstracts the numerical ridge algorithm
  and assumes the existing fit path returns normally on in-domain inputs.
- Related proof obligations: PO-002, PO-005.
- Classification: proof scope boundary, not a code bug.
- Status: keep existing numerical tests; do not remove tests based on this
  constructed proof.

## Proof-derived findings from /verify

No failing verification condition or adequacy mismatch was found for the
constructor/flag-propagation slice. The proof remains constructed, not
machine-checked, because the task forbids running K tooling.

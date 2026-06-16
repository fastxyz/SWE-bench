# FVK Findings

Status: constructed, not machine-checked. Findings are based on public issue
intent, source inspection, and proof-obligation construction.

## F-001: V1 Correctly Localized the Reported IndexError

- Classification: code bug, fixed by V1 and retained in V2.
- Evidence: E-001, E-002, E-004; proof obligations O-001 and O-002.
- Input family: valid `LogisticRegressionCV(refit=False, multi_class='auto')`
  fits where the resolved mode is OvR, including binary problems and
  `solver='liblinear'`.
- Observed before V1: the no-refit block checked `self.multi_class == 'ovr'`.
  When the constructor value was `'auto'`, it took the multinomial indexing
  branch even though the coefficient path had the OvR rank.
- Expected: use the resolved local `multi_class` value so an OvR-shaped path is
  indexed with the OvR index form.
- Resolution: V2 keeps the V1 change from `self.multi_class` to `multi_class`.

## F-002: V1 Left One Elastic-Net-Only Shape Guard Keyed to the Raw Constructor Input

- Classification: code bug, fixed in V2.
- Evidence: E-006, E-008; proof obligation O-005.
- Input family: a valid non-elastic-net fit where `l1_ratios` is supplied even
  though it is ignored, for example `penalty='l1'` or `penalty='l2'` with a
  non-`None` `l1_ratios` argument.
- Observed in V1: validation warned and set local `l1_ratios_` to `[None]`,
  but the final attribute reshape still checked `self.l1_ratios is not None`.
  That could add an l1-ratio axis to `coefs_paths_`, `scores_`, and `n_iter_`
  despite the active penalty not being elastic-net.
- Expected: the l1-ratio dimension is present only when
  `penalty == 'elasticnet'`.
- Resolution: V2 changes the final reshape guard to
  `self.penalty == 'elasticnet'`.

## F-003: V1's Non-Elastic-Net l1_ratio_ Guard Is Required for the Reported Default Penalty

- Classification: code bug, fixed by V1 and retained in V2.
- Evidence: E-003, E-006, E-007; proof obligation O-004.
- Input family: the reported reproducer uses the default non-elastic-net
  penalty and therefore local `l1_ratios_ == [None]`.
- Observed before V1: after fixing the branch selection, the no-refit code
  would still attempt to vector-index and average the l1-ratio grid even when
  no l1 ratio exists.
- Expected: non-elastic-net fits record `None` for `l1_ratio_`.
- Resolution: V2 keeps the V1 guard `if self.penalty == 'elasticnet'` and
  appends `None` otherwise.

## F-004: Proof Is Constructed Only

- Classification: proof capability gap, not a code bug.
- Evidence: environment instruction forbids running tests, Python, or K tools.
- Observed: the proof obligations and K claims were written but not executed
  with `kompile` or `kprove`.
- Expected for machine verification: run the commands listed in `PROOF.md` and
  require `kprove` to return `#Top`.
- Resolution: no code change. Keep test removal as recommendation-only until a
  real K/toolchain pass is possible.

## F-005: Elastic-Net List-Like l1_ratios Need Vector-Compatible Selection

- Classification: compatibility preservation, fixed by V1 and retained in V2.
- Evidence: E-006; proof obligation O-004.
- Input family: elastic-net fits where `l1_ratios` is a valid list-like object
  rather than already being a NumPy array.
- Observed before V1: the no-refit path indexed `l1_ratios_` with the
  per-fold best-index array. That is compatible with NumPy arrays but not with
  all accepted list-like constructor inputs.
- Expected: accepted list-like `l1_ratios` should be selectable by the fold
  winner array without changing public input requirements.
- Resolution: V2 keeps the V1 `np.asarray(l1_ratios_)` conversion at the
  selection point.

## Unresolved Code Findings

None within the audited no-refit branch and elastic-net shape contract.

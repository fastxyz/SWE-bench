# FVK Notes

## Decision summary

I revised V1 rather than leaving it unchanged. V1 fixed the reported
`sample_weight` crash, but the FVK audit identified an avoidable proof burden:
support checking, fitting, and `named_estimators_` alignment each filtered
non-`None` estimators separately. V2 centralizes that filtered list as
`non_none_estimators`.

## Source change

Changed `repo/sklearn/ensemble/voting.py`.

- Introduced `non_none_estimators = [(name, est) for name, est in
  self.estimators if est is not None]`.
- Made the `sample_weight` support loop iterate over `non_none_estimators`.
- Made the `Parallel` fit iterable iterate over `non_none_estimators`.
- Made `named_estimators_` zip `non_none_estimators` with `self.estimators_`.
- Replaced the now-unused `clfs` tuple with a direct list of estimator names
  for `_validate_names`.

Trace to FVK:

- Finding F1 and proof obligations PO2/PO3 justify skipping dropped estimators
  during weighted support checks and fitting only active estimators.
- Finding F2 and proof obligations PO1/PO6 justify centralizing the active
  estimator sequence instead of relying on duplicated filters.
- Finding F3 and PO6 justify preserving the V1 correction that
  `named_estimators_` aligns with fitted non-`None` estimators.
- PO7 confirms that unrelated validation behavior remains framed: invalid
  estimator-list checks, weights-length checks, name validation, and the
  all-dropped error branch remain in place.

## Decisions kept from V1

The core V1 behavior stands: dropped estimators are ignored by the
`sample_weight` support check. This is required by Findings F1 and obligations
PO2/PO3.

The V1 `named_estimators_` alignment fix also stands. Although the reported
traceback was in the support check, Finding F3 shows that the same
filtered/non-filtered mismatch could misname fitted estimators. PO6 captures the
required alignment, and the public docs describe `named_estimators_` as access
to fitted estimators.

## Verification limits

The FVK proof is constructed, not machine-checked. Per Finding F4 and PO8, I did
not run tests, Python, `kompile`, `kast`, or `kprove`, and no test files were
modified. The emitted commands in `fvk/PROOF.md` are for a future environment
with K installed.

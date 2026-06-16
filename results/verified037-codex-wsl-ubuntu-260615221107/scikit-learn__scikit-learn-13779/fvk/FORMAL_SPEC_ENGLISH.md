# Formal Spec In English

The `.k` artifacts are constructed, not machine-checked.

`active(ES)` is the estimator list obtained by removing every estimator record
whose dropped flag is true. `names(active(ES))` is the ordered list of names for
that filtered list.

`FIT-SAMPLE-WEIGHT-ACTIVE` says: for any estimator list whose active portion is
non-empty and whose active estimators all support `sample_weight`,
`fitVoting(ES, true)` succeeds. It fits exactly the active estimator names and
builds `named_estimators_` with exactly the same active estimator names.

`FIT-REPORTED-EXAMPLE` says: for the issue example shape where `lr` is dropped
and `rf` is active and supports sample weights, weighted fit succeeds with only
`rf` in the fitted and named-fitted outputs.

`FIT-ACTIVE-UNSUPPORTED` says: if `sample_weight` is passed and the filtered
active estimator list contains an estimator without `sample_weight` support,
fit reports that active estimator as unsupported.

`FIT-ALL-DROPPED` says: if filtering out dropped estimators leaves no active
estimators, fit reports the existing all-dropped error.

`FIT-NO-SAMPLE-WEIGHT` says: without `sample_weight`, fit does not perform a
sample-weight support check and succeeds on exactly the active estimator names
when at least one active estimator remains.

The model abstracts away actual base-estimator learning, cloning internals,
label encoding, numpy arrays, and joblib scheduling. Those are framed because
the issue concerns routing and support-check behavior around dropped
estimators.

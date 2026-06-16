# Formal Spec in English

Status: constructed, not machine-checked.

The formal core is in `mini-iforest-api.k` and
`iforest-warm-start-spec.k`. It models the observable constructor state that is
relevant to this issue, not full Python execution.

## Claim `IFOREST-DEFAULT-WARM-START`

For any values of the pre-existing `IsolationForest` constructor arguments
`n_estimators`, `max_samples`, `contamination`, `max_features`, `bootstrap`,
`n_jobs`, `behaviour`, `random_state`, and `verbose`, constructing without the
new parameter produces an estimator state with:

- all old arguments stored under their previous names;
- `warm_start` stored as `false`.

This is the formal default-behavior and positional-compatibility claim.

## Claim `IFOREST-EXPLICIT-WARM-START`

For any values of the same old constructor arguments and any boolean
`warm_start` value `W`, constructing with the explicit new argument produces an
estimator state with:

- all old arguments stored under their previous names;
- `warm_start` stored as `W`.

This is the formal public exposure and pass-through claim.

## Claim `IFOREST-POSITIONAL-COMPAT`

For a concrete old positional call carrying distinct symbolic values for
`n_jobs`, `behaviour`, `random_state`, and `verbose`, the constructed state still
maps those four values to those same four fields, and sets only the new
`warm_start` field to `false`.

This claim distinguishes V2 from V1: V1 would have assigned the old `n_jobs`
argument to `warm_start` and shifted the remaining positional fields.

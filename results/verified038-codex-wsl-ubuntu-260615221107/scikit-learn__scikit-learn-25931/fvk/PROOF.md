# Proof

Status: constructed, not machine-checked.

## Reproduce the machine check later

These commands are emitted for a future environment with K installed. They were
not run in this benchmark session.

```sh
kompile fvk/mini-iforest.k --backend haskell
kast --backend haskell fvk/iforest-fit-spec.k
kprove fvk/iforest-fit-spec.k
```

Expected result after successful machine checking: `#Top` for all claims.

## Proof shape

The proof uses the small K model in `mini-iforest.k`. The model is intentionally
property-complete for this bug: it represents input container kind, whether
feature names were recorded, warning emission, the fitted marker, sparse
scoring representation, and the abstract offset expression.

There are no loops in the modeled control-flow slice, so no circularity claim
is required. Each proof is a finite reachability derivation by semantic rule
application and transitivity.

## C-FIT-NON-AUTO-NO-WARNING

Start from `fit(df(N), fixed(C))` with `N > 0` and `C > 0`.

1. The `fit` rule rewrites to `validateFit(df(N)) ~> finishFit(fixed(C))`.
2. `validateFit(df(N))` records `<namesSeen> true </namesSeen>` and returns
   `dense(N)`.
3. `finishFit(fixed(C))` rewrites to
   `privateScoreSamples(dense(N)) ~> setOffsetFromScore(C)`.
4. `privateScoreSamples(dense(N))` rewrites to `raw(dense(N))` without any rule
   that inspects `<namesSeen>` or appends to `<warnings>`.
5. `setOffsetFromScore(C)` stores `percentile(raw(dense(N)), C)` in
   `<offset>`, marks `<fitted> true </fitted>`, and terminates.

The final warning cell is still `.List`, so the reported feature-name warning
is absent.

## C-FIT-NON-AUTO-OFFSET-FRAME

The same derivation shows the offset expression is the percentile of the raw
score on the validated dense training representation. Since `raw(...)` and
`percentile(...)` are uninterpreted but stable, this proves the call-shape frame
condition: V1 removes the second validation but preserves the scored data
representation for the non-auto offset.

## C-PUBLIC-SCORE-ARRAY-AFTER-NAMES-WARNS

Start from `publicScoreSamples(arr(N))` with `<namesSeen> true </namesSeen>`.

1. Public scoring rewrites to `validateScore(arr(N)) ~> finishPublicScore`.
2. `validateScore(arr(N))` with names already seen appends
   `invalidFeatureNames` to `<warnings>` and returns `dense(N)`.
3. `finishPublicScore` delegates to `privateScoreSamples(dense(N))`.
4. The private scorer returns `raw(dense(N))`.

This preserves the public warning behavior for user calls after fitting with
feature names.

## C-PUBLIC-SCORE-DATAFRAME-AFTER-NAMES-NO-WARN

Start from `publicScoreSamples(df(N))` with `<namesSeen> true </namesSeen>`.
Validation returns `dense(N)` without a warning, then the private scorer returns
`raw(dense(N))`. This proves that public scoring of a valid DataFrame remains
warning-free and delegates to the same score computation.

## C-FIT-AUTO-UNCHANGED

Start from `fit(df(N), auto)`.

The derivation validates the DataFrame and records names, then
`finishFit(auto)` stores `autoOffset`, marks the estimator fitted, and
terminates. No training-data scoring operation is used in this branch, matching
the existing auto-contamination behavior.

## C-SPARSE-FIT-SCORES-CSR

Start from `fit(csc(N), fixed(C))`.

1. Sparse fit validation returns the fitting representation `fitCsc(N)`.
2. Fixed-contamination fit delegates to `privateScoreSamples(fitCsc(N))`.
3. The private scorer rewrites sparse fitting data to `raw(scoreCsr(N))`.
4. `setOffsetFromScore(C)` stores `percentile(raw(scoreCsr(N)), C)`.

This discharges the sparse preservation obligation introduced by bypassing the
public scorer's CSR validation conversion.

## C-PRIVATE-SCORE-NO-VALIDATION-WARNING

`privateScoreSamples(dense(N))` has a single modeled dense rule:
it rewrites to `raw(dense(N))`. No rule in the private scorer reads
`<namesSeen>` or updates `<warnings>`, so it cannot emit the feature-name
warning.

## Residual risk and honesty gate

This proof is constructed, not machine-checked. The raw scoring and percentile
operations are abstract, so existing numerical, performance, and integration
tests remain valuable. Test removal is not recommended from this un-run proof.

The proof is partial correctness for the modeled control flow. It does not
prove termination or the full numerical IsolationForest algorithm.

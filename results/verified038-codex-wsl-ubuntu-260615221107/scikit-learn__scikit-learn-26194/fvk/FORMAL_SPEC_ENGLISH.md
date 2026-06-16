# Formal Spec in English

Status: constructed, not machine-checked.

C1. For any list of observed finite thresholds `TS`, `prependStart(TS)` returns
`Inf ; TS`.

C2. If every finite threshold in `TS` is in `[0, 1]`, then every finite
threshold in `Inf ; TS` is still in `[0, 1]`.

C3. `Inf` is strictly above every finite score in the model, so applying the
predicate `score >= Inf` selects no finite score.

C4. The legacy `max + 1` behavior has a counterexample: for max probability
score `1`, it prepends finite threshold `2`, which is above 1.

C5. The clipping workaround has a counterexample: if an observed score is
exactly `1`, a first threshold clipped to `1` does not select no samples.

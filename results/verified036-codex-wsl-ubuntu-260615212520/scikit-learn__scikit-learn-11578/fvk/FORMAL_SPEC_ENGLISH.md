# Formal Spec English Paraphrase

Status: constructed, not machine-checked.

## Claim `SCORER-PARAMS`

For any valid parameter bundle `P`, candidate regularization value `C`,
candidate coefficients `W`, and `fit_intercept` setting, running the
scorer-candidate construction produces an estimator whose parameter bundle is
`P` extended with the current `C`. No constructor parameter named in the public
hint is replaced by a `LogisticRegression` default.

## Claim `MULTINOMIAL-SOFTMAX`

For any candidate constructed from a parameter bundle whose `multi_class` value
is `multinomial`, the probability branch visible from the constructed estimator
is `softmaxBranch`.

## Claim `SCORE-ALL-CANDIDATES`

For any aligned list of candidate `Cs` and candidate coefficient rows, the
scoring loop appends exactly one scorer call per candidate. The nth call uses
the nth `C`, the nth coefficient row, the requested `fit_intercept` handling,
and the probability branch determined by the original `multi_class` value.

## Frame conditions

The formal claims do not change the public helper signature, the return tuple,
the class label assignment branch, or the existing coefficient/intercept shape
rules. They only constrain the estimator object that is visible to scoring.

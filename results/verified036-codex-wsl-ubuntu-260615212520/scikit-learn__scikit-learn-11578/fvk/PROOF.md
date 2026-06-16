# Constructed Proof

Status: constructed, not machine-checked. No `kompile`, `kast`, `kprove`, tests,
Python, or project code were executed.

## Claims

The formal core is:

- `fvk/mini-logistic-scoring.k`
- `fvk/log-reg-scoring-spec.k`

The claims are:

- `SCORER-PARAMS`
- `MULTINOMIAL-SOFTMAX`
- `SCORE-ALL-CANDIDATES`

## Proof sketch

### `SCORER-PARAMS`

Start from `scoreCandidate(P, C, W, FI)`. The single semantic rule for
`scoreCandidate` rewrites the computation to `.K`, writes
`estimator(withC(P, C), coefFor(W, FI), interceptFor(W, FI))` into the
estimator cell, and writes the branch determined by `multiClassOf(P)`.

The helper function `withC` is structurally defined over the full parameter
bundle. Its rewrite rule copies every constructor parameter from `P` and appends
the current `C`. By consequence, the final estimator preserves all parameters
named in PO-001 and has the current `C` required by PO-002.

### `MULTINOMIAL-SOFTMAX`

Instantiate `P` with `multi_class=multinomial`. Symbolic execution applies the
same `scoreCandidate` rule. The branch cell becomes
`branchOf(multiClassOf(P))`. The function rules reduce
`multiClassOf(P)` to `multinomial` and then `branchOf(multinomial)` to
`softmaxBranch`.

This exactly corresponds to `LogisticRegression.predict_proba`, where
`self.multi_class == "ovr"` selects OvR normalization and all other accepted
values, including `multinomial`, select softmax.

### `SCORE-ALL-CANDIDATES`

The claim is a structural loop/circularity over aligned `CList` and `WList`.

Base case: for `.CList` and `.WList`, the `scoreAll` base rule rewrites the
computation to `.K` and leaves `.CallList`, which equals
`expectedCalls(P, .CList, .WList, FI)`.

Step case: for `ccons(C, CS)` and `wcons(W, WS)`, the semantic rule appends a
call containing `estimator(withC(P, C), coefFor(W, FI), interceptFor(W, FI))`
and `branchOf(multiClassOf(P))`, then continues with
`scoreAll(P, CS, WS, FI)`. The circularity hypothesis applies to the tail
because the step has made genuine progress by consuming one candidate pair.
The post-state is therefore the head call followed by
`expectedCalls(P, CS, WS, FI)`, which is exactly
`expectedCalls(P, ccons(C, CS), wcons(W, WS), FI)`.

No nonlinear arithmetic verification conditions arise.

## Adequacy gate

`FORMAL_SPEC_ENGLISH.md` paraphrases each claim. `SPEC_AUDIT.md` compares those
paraphrases against `INTENT_SPEC.md`; every required behavior passes. The proof
does not certify numerical softmax/log-loss values, and `FINDINGS.md` records
that limit as F-005.

## Test recommendation

Because this proof is constructed but not machine-checked, no test removal is
recommended. Public tests around custom scorers and `LogisticRegressionCV`
should be kept, and hidden tests remain the fixed evaluator.

## Commands to machine-check later

These commands are recorded for a suitable environment and were not run:

```sh
kompile fvk/mini-logistic-scoring.k --backend haskell
kast --backend haskell fvk/log-reg-scoring-spec.k
kprove fvk/log-reg-scoring-spec.k
```

Expected result after a successful machine check: `kprove` returns `#Top`.

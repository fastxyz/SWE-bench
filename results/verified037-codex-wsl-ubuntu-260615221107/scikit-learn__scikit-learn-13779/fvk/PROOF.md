# Constructed Proof

Status: constructed, not machine-checked. No `kompile`, `kast`, or `kprove`
commands were executed.

## Claims Proved In The Model

The model in `mini-python.k` evaluates `fitVoting(ES, SW)` by first computing
`active(ES)`, the order-preserving list of non-dropped estimators. The claims
in `voting-fit-spec.k` then cover the weighted-success, reported-example,
active-unsupported, all-dropped, and no-sample-weight branches.

## Proof Sketch

For `FIT-SAMPLE-WEIGHT-ACTIVE`, symbolic execution applies the
`fitVoting(ES, true)` rule, reducing the command to
`fitActive(active(ES), true)`. The precondition states that `active(ES)` is
non-empty and has no unsupported active estimator. Therefore the successful
weighted `fitActive` rule applies and returns
`ok(names(active(ES)), names(active(ES)))`. The first component represents
`estimators_` names; the second represents `named_estimators_` keys. Since both
are derived from the same `active(ES)`, name/fitted alignment follows.

For `FIT-REPORTED-EXAMPLE`, `active(est(lr,true,true);;est(rf,false,true);;.Ests)`
rewrites to `est(rf,false,true);;.Ests`. The active list is non-empty and has no
unsupported estimator, so the same success rule returns only `rf` in both
outputs. No rule inspects or fits `lr`.

For `FIT-ACTIVE-UNSUPPORTED`, symbolic execution again reduces through
`active(ES)`. The precondition states that an unsupported active estimator
exists, so the unsupported branch returns
`errorUnsupported(firstUnsupported(active(ES)))`.

For `FIT-ALL-DROPPED`, the precondition `isEmpty(active(ES))` enables the
`fitActive(.Ests, SW) => errorAllNone` rule after filtering. This preserves the
all-dropped error.

For `FIT-NO-SAMPLE-WEIGHT`, symbolic execution reduces to
`fitActive(active(ES), false)`. The non-empty active-list precondition enables
the no-sample-weight success rule, which does not check sample-weight support.

## Connection To Source

The V2 source-level expression
`non_none_estimators = [(name, est) for name, est in self.estimators if est is
not None]` is the implementation of `active(ES)`.

The weighted support loop, the `Parallel` fit iterable, and the
`named_estimators_` construction all consume `non_none_estimators`. This
discharges PO2, PO3, and PO6 without relying on separate filters that merely
happen to match.

## Exact Commands To Run Later

These commands are emitted for later machine-checking; they were not executed.

```sh
cd fvk
kompile mini-python.k --backend haskell
kast --backend haskell voting-fit-spec.k
kprove voting-fit-spec.k
```

Expected machine-check result after installing/running the K toolchain:
`kprove` returns `#Top` for the claims.

## Residual Risk

The proof is partial correctness over the routing abstraction. It does not
prove termination, performance, actual estimator learning, numpy validation,
label encoding, or joblib internals. It assumes ordered collection of `Parallel`
results.

## Test Redundancy Recommendation

No tests were modified. After machine-checking only, tests that assert the
specific routing behavior "dropped estimators are skipped during weighted fit"
would be logically subsumed by `FIT-REPORTED-EXAMPLE` and
`FIT-SAMPLE-WEIGHT-ACTIVE`. Keep integration tests, estimator-specific behavior
tests, validation/error-order tests, and all tests outside the formal domain.

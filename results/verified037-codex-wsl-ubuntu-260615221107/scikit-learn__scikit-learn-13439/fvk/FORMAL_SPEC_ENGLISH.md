# Formal Spec English

This file paraphrases every nontrivial K claim and side condition.

## Claim LEN

For every non-negative integer `N`, if `pipeline(N)` represents a `Pipeline`
whose `steps` sequence has cardinality `N`, then evaluating
`pipelineLen(pipeline(N))` terminates with integer result `N`.

## Claim FULL-SLICE-AFTER-LEN

For every non-negative integer `N`, if `pipeline(N)` represents a `Pipeline`
whose `steps` sequence has cardinality `N`, then evaluating the full-prefix
slice expression represented by `slicePrefix(pipeline(N),
pipelineLen(pipeline(N)))` terminates with `pipeline(N)`.

## Side Conditions

`N >= 0` states that sequence cardinality is non-negative. The slice rule also
requires `0 <= K <= N`; in the full-slice claim, `K` is produced by the length
claim, so `K == N` and the side condition follows.

## Frame Conditions

The formal spec does not introduce `__iter__` or other sequence methods. It
models only the new length method and the already-existing full-prefix slice
path needed by the issue.

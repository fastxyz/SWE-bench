# FVK Proof

Status: constructed, not machine-checked. No K command was executed.

## Claim Summary

For every valid groupBy result-level cache entry produced for the same query shape, `pullFromCache(true)` restores the post-aggregator suffix into `ResultRow` slots starting at `query.getResultRowPostAggregatorStart()` in the same order that `prepareForCache(true)` emitted them.

## Machine-Check Commands Not Run

```sh
kompile fvk/mini-java-cache.k --backend haskell
kast --backend haskell fvk/groupby-cache-spec.k
kprove fvk/groupby-cache-spec.k
```

Expected machine-check result, if the reduced model and claims are accepted: `#Top`.

## Definitions

Let:

- `P` be the number of post-aggregator specs.
- `S` be `query.getResultRowPostAggregatorStart()`.
- `V[0..P-1]` be the post-aggregator suffix of the valid cache object.
- `R` be the output `ResultRow` allocated by `pullFromCache(true)`.

The proof is partial correctness over valid cache entries. Termination is immediate for the modeled loop because `postPos` increases by one and is bounded by `P`; this is stated as a simple finite-loop fact, not machine-checked.

## Loop Invariant

At the start of an iteration with `postPos == k`:

1. `0 <= k <= P`.
2. For every `j < k`, `R[S + j] == V[j]`.
3. The next unread post-aggregator cache value, if `k < P`, is `V[k]`.

## Base Case

Before the loop starts, `postPos == 0`. There are no `j < 0`, so the restored-prefix property is vacuously true.

## Step Case

Assume the invariant holds for `k` and `k < P`. V1 executes:

```java
resultRow.set(postAggregatorStart + postPos++, results.next());
```

The write target is `S + k`; the read value is `V[k]`; after the statement, `postPos == k + 1`. Therefore every slot `S + j` for `j < k + 1` contains `V[j]`: old slots by the induction hypothesis, and the new slot by the current write. Because the destination uses `k`, not a constant zero, the step cannot overwrite an earlier restored post-aggregator slot.

## Exit Case

The loop is bounded by `postPos < P`. On valid cache entries there are exactly `P` post-aggregator values, so after `P` iterations `postPos == P` and the loop exits. By the invariant, every `i` in `[0, P)` has `R[S + i] == V[i]`.

## Composition with Producer

`prepareForCache(true)` appends post-aggregator values by incrementing `inPos` once per post-aggregator. Row-layout methods place post-aggregator `i` at `S + i`. Therefore the cache suffix value `V[i]` equals the original row's post-aggregator slot `S + i`. The restore proof then yields the same value at `R[S + i]`.

## Counterexample Against Pre-V1

For `P = 2` and cache suffix `[V0, V1]`, the pre-V1 loop wrote:

- iteration 0: `R[S + 0] = V0`
- iteration 1: `R[S + 0] = V1`

Slot `S + 1` remained the null value from `ResultRow.create`. This derives the public symptom: the first post-aggregator slot receives the later value and the later slot remains null.

## Adequacy Result

The formal claim covers the entire public bug family, not only the sample query: any valid result-level cache entry with `P >= 0` post-aggregators. In particular, `P >= 2` is covered by the same invariant that covers `P == 0` and `P == 1`.

## Residual Risk

The proof is a reduced-model proof, not a full Java/K proof of Apache Druid. It does not prove behavior for malformed cache objects, cache entries from a different query shape, or concurrent mutation of query metadata. Those cases are outside the public repair intent recorded in `SPEC.md`.

## Test Guidance

No tests were inspected, modified, removed, or run. A future public test with a groupBy result-level cache entry containing two or more post-aggregators is directly subsumed by PO-4 only after the K proof is machine-checked. Integration tests of cache wiring should be kept because this unit proof covers only the restoration loop and producer/consumer ordering.

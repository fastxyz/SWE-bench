# FVK Proof Obligations

Status: constructed, not machine-checked.

## PO-1: Result-Level Cache Producer Shape

For `prepareForCache(true)`, after timestamp, dimensions, and aggregators are appended, the function appends exactly `P = query.getPostAggregatorSpecs().size()` post-aggregator values. For every `i` in `[0, P)`, cached suffix value `V[i]` equals the source `ResultRow` value at `S + i`, where `S = query.getResultRowPostAggregatorStart()`.

Status: discharged by static source inspection of `prepareForCache(true)` and row-layout evidence E4-E5.

## PO-2: Restore Loop Bound

For `pullFromCache(true)`, the post-aggregator restoration loop must execute no more than `P` post-aggregator writes for the query.

Status: discharged by V1's loop condition `postPos < query.getPostAggregatorSpecs().size() && results.hasNext()`.

## PO-3: Restore Loop Progress and No Same-Slot Overwrite

For each loop iteration starting with `postPos == k`, `0 <= k < P`, and next cached post-aggregator value `V[k]`, the loop writes to `S + k` and then establishes `postPos == k + 1`.

Status: discharged by V1's `resultRow.set(postAggregatorStart + postPos++, results.next())`.

## PO-4: Post-Aggregator Segment Round-Trip

Under the valid-cache precondition, after `pullFromCache(true)` completes, for every `i` in `[0, P)`, the output row has `R[S + i] == V[i]`. Combined with PO-1, this means the post-aggregator segment round-trips.

Status: discharged by induction over PO-2 and PO-3.

## PO-5: Frame Conditions

The fix must not change timestamp restoration, dimension restoration, aggregator restoration, cache-key construction, segment-level cache behavior, or the serialized result-level cache object shape.

Status: discharged by diff inspection. V1 edits only the result-level-cache post-aggregator read loop and removes an unused import.

## PO-6: Public Compatibility

No public method signature, return type, virtual dispatch contract, or producer/consumer storage format may change.

Status: discharged by `PUBLIC_COMPATIBILITY_AUDIT.md`. V1 changes only internal restoration indexing.

## PO-7: Honesty Gate

The constructed K proof must not be presented as machine-checked, and test-removal recommendations must remain conditional on running the emitted K commands.

Status: discharged by labeling `SPEC.md`, `PROOF.md`, and related artifacts "constructed, not machine-checked" and by not deleting or modifying tests.

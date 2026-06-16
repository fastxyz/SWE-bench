# FVK Notes

## Decision summary

V1 stands unchanged after the FVK audit. The audit produced the required five FVK artifacts plus the supporting adequacy and reduced K files under `fvk/`, but it did not justify any additional production source edit.

## Decisions traced to FVK evidence

- Kept the V1 post-aggregator write `postAggregatorStart + postPos++`.
  - Trace: `fvk/FINDINGS.md` F1 identifies the pre-V1 same-slot overwrite; `fvk/PROOF_OBLIGATIONS.md` PO-3 requires each iteration to write slot `S + k` and then establish `postPos == k + 1`.
  - Reason: the V1 expression is exactly the loop-step proof obligation and removes the public symptom where a later post-aggregator overwrote an earlier slot.

- Kept the V1 count-bounded loop condition `postPos < query.getPostAggregatorSpecs().size() && results.hasNext()`.
  - Trace: `fvk/FINDINGS.md` F2 identifies the unadvanced `PostAggregator` iterator as a pre-V1 issue; `fvk/PROOF_OBLIGATIONS.md` PO-2 requires a loop bound tied to the query's post-aggregator count.
  - Reason: the V1 condition makes the proof's `P` bound explicit and avoids preserving the stale iterator behavior.

- Did not add a new exception for truncated or malformed cache rows.
  - Trace: `fvk/FINDINGS.md` F3 records malformed cache rows as a residual assumption; `fvk/PROOF_OBLIGATIONS.md` PO-1 and PO-4 define the repaired domain as valid cache entries produced by `prepareForCache(true)` for the same query shape.
  - Reason: the public issue is a valid result-level cache round-trip bug. Adding new malformed-cache validation would be a broader behavior change not required by the public intent.

- Did not change cache keys, serialized cache shape, timestamps, dimensions, aggregators, or public APIs.
  - Trace: `fvk/FINDINGS.md` F4 and `fvk/PROOF_OBLIGATIONS.md` PO-5/PO-6.
  - Reason: the bug localizes to post-aggregator slot restoration; compatibility evidence supports preserving all other behavior.

- Added reduced FVK K artifacts without running them.
  - Trace: `fvk/PROOF_OBLIGATIONS.md` PO-7 and `fvk/PROOF.md`.
  - Reason: FVK requires machine-checkable artifacts and exact commands, but this task prohibits running K tooling. The artifacts are labeled constructed, not machine-checked.

## Source changes after V1

None. The only production source diff remains the V1 fix in `repo/processing/src/main/java/org/apache/druid/query/groupby/GroupByQueryQueryToolChest.java`.

## Test and execution policy

No tests, Python, or K framework commands were run. No test files were modified.

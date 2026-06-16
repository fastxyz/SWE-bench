# Formal Spec, English Paraphrase

## Claim DISABLED-COMPUTE

For any `Similar` state with any collected line sets, if `min_lines <= 0`,
calling `_compute_sims()` returns the empty similarity list. It does not inspect
file-pair combinations or call the normal matching path.

## Claim DISABLED-PROCESS

For any `SimilarChecker` state with any current `linesets`, if `min_lines <= 0`,
`process_module(node)` returns without reading the module stream and without
adding a `LineSet`.

## Claim DISABLED-CLOSE

For any `SimilarChecker` state whose `_compute_sims()` result is empty,
`close()` iterates zero similarity groups, emits no `R0801` message, and leaves
duplicate statistics at zero.

## Claim POSITIVE-PRESERVATION

For `min_lines > 0`, the new guards do not fire. The previous positive-threshold
body of `_compute_sims()` and `process_module()` is reached unchanged.

## Claim PARALLEL-REDUCE

In the map/reduce path, the reducer copies the originating `min_lines` value into
the recombined checker before closing it. Therefore the disabled close behavior
also holds for parallel runs.

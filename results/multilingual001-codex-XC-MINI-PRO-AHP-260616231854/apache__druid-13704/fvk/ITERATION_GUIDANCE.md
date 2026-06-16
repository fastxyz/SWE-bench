# FVK Iteration Guidance

Status: constructed, not machine-checked.

## Decision

Keep V1 production code unchanged. The FVK audit found no source-code defect in V1 relative to the public intent. V1 already:

- registers `pow` as a known arithmetic post-aggregator function;
- delegates pairwise operation semantics to `Math.pow`;
- inherits existing null propagation and left-to-right folding;
- preserves field order in cache keys for the new non-commutative operation;
- leaves existing public signatures and operations unchanged.

## Recommended Future Work

- Add public tests for `pow` construction, square/cube/square-root examples, null propagation, and cache-key order sensitivity in a normal development workflow.
- Update user-facing native post-aggregator documentation to list `pow` when this feature lands outside the benchmark setting.
- Machine-check the K artifacts with the commands in `fvk/PROOF.md` when a K environment is available.

## Do Not Change

- Do not add a `power` alias without a separate product decision. The public evidence supports `pow`.
- Do not make `pow` binary-only. Existing arithmetic post-aggregator docs specify left-to-right evaluation of the provided function over the fields list.
- Do not remove or edit tests as part of this benchmark.

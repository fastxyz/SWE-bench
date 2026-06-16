# Iteration Guidance

Constructed, not machine-checked.

## Source Decision

V1 stands unchanged.

The FVK audit found no residual source-code defect relative to the public
intent. The full generated unittest/xunit setup fixture-name family is covered,
the names now feed the existing underscore hide rule, and the behavior frame is
preserved.

## Next Actions Outside This Benchmark

1. Machine-check the FVK claims with the commands in `fvk/PROOF.md`.
2. Keep existing tests until the proof is machine-checked.
3. Add or maintain project tests for non-verbose and verbose fixture-listing
   behavior across the generated fixture family.

## Risks To Watch

- Future generated fixture registrations should use underscore-prefixed names if
  they are internal autouse setup/teardown helpers.
- Any future fixture-listing refactor must preserve the documented behavior that
  underscore-prefixed fixtures are hidden unless verbose output is requested.

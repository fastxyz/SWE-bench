# FVK Findings

Status: constructed, not machine-checked.

## F-01: Original `builtin`/`builtins` Mismatch

- Classification: code bug in V0, resolved by V1.
- Evidence: problem statement says `PTH123` and `S102` "check `builtin` instead of `builtins`".
- Concrete input: resolved call target `qname("builtins", "exec")`.
- V0 observed: no `S102` diagnostic because the match accepted `""` or `"builtin"`.
- Expected: emit `S102`, because the standard-library module is `builtins`.
- V1 status: satisfied by `["" | "builtins", "exec"]` in `exec_used.rs`.

## F-02: False Positive on Non-Standard `builtin`

- Classification: code bug in V0, resolved by V1.
- Evidence: problem statement shows `import builtin` followed by `builtin.open(...)` and `builtin.exec(...)` incorrectly reported.
- Concrete input: resolved call targets `qname("builtin", "open")` and `qname("builtin", "exec")`.
- V0 observed: `PTH123` and `S102` diagnostics emitted.
- Expected: no diagnostics from these rules, because `builtin` is not the standard-library module.
- V1 status: satisfied because neither rule now accepts the `"builtin"` segment.

## F-03: Frame Condition for Existing `PTH123` Exclusions

- Classification: preserved behavior, no code change required.
- Evidence: `replaceable_by_pathlib.rs` already excludes file descriptors and non-default `closefd` or `opener` arguments because `Path.open` cannot represent those cases.
- Concrete input: resolved call target `qname("builtins", "open")` with any exclusion flag true.
- Expected: no `PTH123` diagnostic.
- V1 status: satisfied because V1 changed only the module segment in the match arm and left the exclusion block unchanged.

## F-04: No Remaining Exact `"builtin"` Matcher in the Audited Source Slice

- Classification: completeness check for this issue, satisfied.
- Evidence: static inspection after V1 found no exact `"builtin"` string match under the relevant linter, semantic, AST, and stdlib source paths.
- Expected: no sibling rule path should continue accepting the singular module name for `S102` or `PTH123`.
- V1 status: satisfied.

## F-05: Proof Status and Execution Boundary

- Classification: proof capability boundary, not a code bug.
- Evidence: the benchmark forbids running tests, Python, or K tooling.
- Expected: record the K commands and reason about their expected result without executing them.
- V1 status: proof is constructed, not machine-checked; no source change follows from this boundary.

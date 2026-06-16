# FVK Notes

## Decision Summary

V1 stands unchanged. The FVK audit found that the V1 source edits discharge the public issue intent without introducing a compatibility or frame-condition problem.

## Decisions Traced to Findings and Proof Obligations

- Kept `repo/crates/ruff_linter/src/rules/flake8_bandit/rules/exec_used.rs` unchanged after V1.
  - `fvk/FINDINGS.md` F-01 identified the original false negative for `builtins.exec`; `fvk/PROOF_OBLIGATIONS.md` PO-01 is discharged by the V1 match `["" | "builtins", "exec"]`.
  - F-02 identified the original false positive for `builtin.exec`; PO-03 is discharged because `"builtin"` is no longer an accepted segment.
  - PO-02 confirms the empty segment remains accepted, preserving unqualified `exec()`.

- Kept `repo/crates/ruff_linter/src/rules/flake8_use_pathlib/rules/replaceable_by_pathlib.rs` unchanged after V1.
  - F-01 identified the original false negative for `builtins.open`; PO-04 is discharged by the V1 match `["" | "builtins", "open"]`.
  - F-02 identified the original false positive for `builtin.open`; PO-06 is discharged because `"builtin"` is no longer an accepted segment.
  - PO-05 confirms the empty segment remains accepted, preserving unqualified `open()`.
  - F-03 and PO-07 justify leaving the existing `closefd`, `opener`, and file-descriptor exclusions untouched.

- Did not add `"builtin"` as an alias.
  - F-02 is exactly the false-positive behavior caused by accepting `"builtin"`.
  - Reintroducing it would violate PO-03 and PO-06.

- Did not refactor `S102` to use `SemanticModel::match_builtin_expr`.
  - PO-01 through PO-03 are already discharged by the current established match style.
  - `fvk/ITERATION_GUIDANCE.md` records this as an unnecessary change for the stated issue.

- Did not change public APIs, diagnostics, rule registrations, or tests.
  - PO-08 confirms the source change is limited to private rule implementation literals.
  - The benchmark forbids test edits, and F-05 records that no tests or K tooling were run.

## Artifacts Produced

- `fvk/SPEC.md`
- `fvk/FINDINGS.md`
- `fvk/PROOF_OBLIGATIONS.md`
- `fvk/PROOF.md`
- `fvk/ITERATION_GUIDANCE.md`
- `fvk/mini-ruff-calls.k`
- `fvk/builtin-module-spec.k`

The K proof is constructed, not machine-checked. The commands needed for a later K-enabled environment are recorded in `fvk/PROOF.md`.

# FVK Notes

## Decisions

- Kept the V1 switch from unconditional `Fix::safe_edit` to conditional `Fix::applicable_edit`. This is justified by F-001 and F-002 and discharges PO-002 and PO-003.
- Edited `repo/crates/ruff_linter/src/rules/flake8_simplify/rules/ast_unary_op.rs` to check `typing::find_binding_value` before annotation-oriented semantic helpers. This resolves F-003 and discharges PO-004 by making initializer evidence decisive for named operands.
- Kept the generated replacement expressions unchanged. This is required by PO-005 and supported by F-001, which identifies fix applicability rather than replacement construction as the bug.
- Kept the conservative fallback to `Applicability::Unsafe` for unknown or ambiguous operands. This follows F-004 and PO-006.
- Did not run tests, Ruff, Python, `kompile`, `kast`, or `kprove`. F-005 and PO-007 require the artifacts to remain constructed, not machine-checked.

## Result

V2 preserves the V1 fix for the reported NumPy case and tightens one over-approximation found by the FVK audit: contradictory annotations can no longer override an unknown initializer when deciding whether SIM201/SIM202 fixes are safe.

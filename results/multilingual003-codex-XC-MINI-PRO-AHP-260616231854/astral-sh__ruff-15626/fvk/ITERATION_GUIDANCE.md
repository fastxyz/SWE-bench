# Iteration Guidance

Status: V2 source change applied; proof constructed, not machine-checked.

## Applied Change

F-003 and PO-004 justified one source edit beyond V1: `operand_eq_ne_returns_bool` now checks `typing::find_binding_value` before `typing::is_int`, `typing::is_float`, or container helpers. This makes initializer evidence decisive and prevents a contradictory annotation from marking an unknown runtime value safe.

## Confirmed V1 Decisions

The V1 decision to replace `Fix::safe_edit` with `Fix::applicable_edit` is confirmed by F-001, F-002, PO-002, and PO-003. The V1 decision to leave diagnostic detection and replacement generation unchanged is confirmed by PO-001 and PO-005.

## Residual Risk

F-004 remains as a conservative incompleteness note: Ruff may mark some truly safe comparisons unsafe if it lacks local evidence. That is acceptable for the issue because it prevents behavior-changing automatic fixes.

F-005 and PO-007 remain process limitations: the proof and commands are constructed only. Do not remove tests or claim machine-checked verification until the emitted commands succeed.

## Suggested Follow-Up Tests

Do not modify tests in this benchmark. For normal development, add or update tests for:

- SIM201/SIM202 unknown operands report unsafe fixes;
- the public NumPy reproducer is not fixed by default `--fix`;
- `a: int = np.array([0])` and `b: int = np.array([1])` are unsafe despite annotations;
- direct built-in literal comparisons remain safe;
- replacement text is unchanged for both rules.

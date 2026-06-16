# Iteration Guidance

Status: constructed, not machine-checked.

## Code Guidance

Keep the V1 empty tuple fix. It discharges F1, PO1, and the `Tuple[()]` portion
of PO4.

Keep the V2 empty list guard. It discharges F2 and PO2 while preserving the
non-empty list behavior required by PO3.

Do not make additional source changes in this iteration. PO5 and PO6 show that
unsupported syntax fallback and public compatibility are already framed by
unchanged code.

## Test Guidance

Do not edit tests in this benchmark task.

Recommended future tests for the fixed public suite:

- `_parse_annotation("Tuple[()]")` renders the name `Tuple`, `[`, `(`, `)`, and
  `]` in order.
- `_parse_annotation("Callable[[], int]")` renders the inner empty list as `[]`.
- Existing tests for `Tuple[int, int]`, `Callable[[int, int], int]`, and
  `List[int]` remain as regression coverage for non-empty formatting.

No existing test should be removed based on this FVK pass because the proof is
constructed, not machine-checked.

## Future Formal Work

The current K model is intentionally small and property-complete for delimiter
output. A stronger future pass could model more of Python's real AST classes and
docutils node construction, but that is not needed to justify the current fix.

## UltimatePowers-Style Clarification If Needed

No user clarification is required for the current issue. If expanding the parser
later, ask which additional annotation AST forms should be rendered structurally
instead of falling back to a single xref.

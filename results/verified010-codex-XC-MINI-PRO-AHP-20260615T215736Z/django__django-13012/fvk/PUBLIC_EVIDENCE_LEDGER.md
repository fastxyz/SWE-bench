# Public Evidence Ledger

This ledger mirrors the evidence table in `SPEC.md`.

- E-001: Problem title states constant expressions of `ExpressionWrapper` are
  incorrectly placed in `GROUP BY`.
- E-002: Problem example shows unwrapped `Value(3)` omitted from `GROUP BY`.
- E-003: Problem says the caller accepts an arbitrary query expression.
- E-004: Public hint says grouping resolution should defer to the wrapped
  expression.
- E-005: `Query.set_group_by()` checks for missing `alias` in
  `get_group_by_cols()` and warns before calling without the keyword.
- E-006: `tests/expressions/test_deprecation.py` documents the exact missing
  alias deprecation behavior.
- E-007: `Value.get_group_by_cols(alias=None)` returns `[]`.
- E-008: `Subquery.get_group_by_cols(alias=...)` is alias-sensitive.

# Proof Obligations

Status: constructed, not machine-checked.

PO1. Same-type temporal subtraction resolves to duration

- Claim IDs: `DATE-SUB`, `DATETIME-SUB`, `TIME-SUB`.
- Required by: findings F1/F2 and evidence E1/E4/E6.
- Obligation: `resolveOutput(SUB, T, T) = DurationField` for each temporal
  field type `T` in `{DateField, DateTimeField, TimeField}`.
- Disposition: discharged by finite case rewrite in the constructed K model.

PO2. The reported nested expression resolves without mixed-type error

- Claim ID: `ISSUE-NESTED-DATETIME-DURATION`.
- Required by: finding F1 and evidence E2/E3.
- Obligation:
  `resolveOutput(ADD, resolveOutput(SUB, DateTimeField, DateTimeField), DurationField) = DurationField`.
- Disposition: discharged by composing PO1 with generic same-type inference.

PO3. SQL specialization remains aligned with output-field inference

- Claim IDs: `SQL-TEMPORAL-SUBTRACTION`,
  `SQL-TEMPORAL-SUBTRACTION-OUTPUT`.
- Required by: finding F2 and evidence E4/E5.
- Obligation: same-type temporal subtraction still takes the
  `TemporalSubtraction` SQL path, and that path has `DurationField` output.
- Disposition: discharged by finite case rewrite in the constructed K model and
  by source inspection showing `as_sql()` was not changed.

PO4. Generic fallback behavior is preserved outside the temporal subtraction
special case

- Claim IDs: `GENERIC-SAME-DURATION`, `GENERIC-MIXED-DATETIME-DURATION`,
  `GENERIC-SAME-INTEGER`.
- Required by: finding F3 and evidence E7.
- Obligation: non-special same-type operands resolve to that type; direct mixed
  known operands still resolve to `FieldError`.
- Disposition: discharged by generic resolver claims.

PO5. Public compatibility is preserved

- Claim source: `fvk/PUBLIC_COMPATIBILITY_AUDIT.md`.
- Required by: finding F4.
- Obligation: no public signatures, virtual dispatch calls, backend SQL APIs, or
  test files are changed.
- Disposition: discharged by source inspection; no code change after V1.

PO6. Honesty gate

- Claim source: `fvk/PROOF.md`.
- Obligation: all proof results are labeled constructed, not machine-checked,
  and no tests are deleted or claimed redundant without that condition.
- Disposition: discharged by artifact wording. No tests were run or modified.

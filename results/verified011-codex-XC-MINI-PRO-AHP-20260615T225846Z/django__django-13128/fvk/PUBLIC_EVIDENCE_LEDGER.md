# Public Evidence Ledger

Status: constructed from public evidence, not machine-checked.

| ID | Source | Evidence | Semantic obligation | Status |
| --- | --- | --- | --- | --- |
| E1 | prompt | "make temporal subtraction work without ExpressionWrapper" | Same-type temporal subtraction must be self-typed as a duration. | Encoded in PO1 and K claims `DATE-SUB`, `DATETIME-SUB`, and `TIME-SUB`. |
| E2 | prompt | `F('end') - F('start') + Value(datetime.timedelta(), output_field=DurationField())` | The inner datetime subtraction must resolve to `DurationField` before the outer addition resolves. | Encoded in PO2 and K claim `ISSUE-NESTED-DATETIME-DURATION`. |
| E3 | prompt | `FieldError: Expression contains mixed types: DateTimeField, DurationField` | The reported mixed-type error is the legacy symptom, not behavior to preserve. | Finding F1 records the pre-V1 defect as resolved by the current source. |
| E4 | source | `TemporalSubtraction.output_field = fields.DurationField()` | SQL-level temporal subtraction already declares duration output. | Encoded in PO3 and K claim `SQL-TEMPORAL-SUBTRACTION`. |
| E5 | source | `CombinedExpression.as_sql()` routes same-type temporal subtraction to `TemporalSubtraction`. | Output-field inference should use the same temporal predicate as SQL rendering. | Encoded in PO3. |
| E6 | public tests | Existing date, time, and datetime subtraction tests wrap subtraction with `ExpressionWrapper(..., output_field=DurationField())`. | Public tests confirm the intended output type for temporal subtraction is duration. | Supporting evidence for PO1; no tests modified. |
| E7 | source | `BaseExpression._resolve_output_field()` raises on mixed source field classes. | Non-special arithmetic should continue to delegate to generic mixed-type inference. | Encoded in PO4. |

No hidden tests, evaluator data, upstream patches, or internet sources were used.

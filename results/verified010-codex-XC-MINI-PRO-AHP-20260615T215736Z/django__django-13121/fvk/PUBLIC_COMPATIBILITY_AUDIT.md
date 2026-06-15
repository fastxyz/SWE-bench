# Public Compatibility Audit

Status: constructed, not machine-checked.

## Changed symbols

`django.db.models.expressions.DurationExpression.compile`

- Change: added an optional internal `duration_only=False` parameter.
- Public compatibility: this is an internal helper method called only inside
  `DurationExpression.as_sql()` in this source file.
- Status: compatible.

`django.db.models.expressions.DurationExpression.has_duration_output`

- Change: added a new internal helper method.
- Public compatibility: no external callsites or subclasses are required to
  implement it.
- Status: compatible.

`django.db.models.expressions.DurationExpression.as_sql`

- Change: internal branch selection for non-native-duration compilation.
- Public compatibility: method signature unchanged; return shape remains
  `(sql, params)`.
- Status: compatible.

## Unchanged interfaces

- Backend operation hook signatures are unchanged.
- `DurationField` storage and converter APIs are unchanged.
- Model/query public APIs are unchanged.
- No test files are modified.

## Finding link

This audit supports F5 and PO6.

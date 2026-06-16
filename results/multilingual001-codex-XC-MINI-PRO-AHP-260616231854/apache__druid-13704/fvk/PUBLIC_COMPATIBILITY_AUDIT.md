# Public Compatibility Audit

Status: constructed, not machine-checked.

## Changed Symbols

- `ArithmeticPostAggregator.Ops`: added enum constant `POW("pow")`.
- `ArithmeticPostAggregator.preserveFieldOrderInCacheKey`: added switch case `POW`.

## Compatibility Results

| Surface | Compatibility result |
| --- | --- |
| Constructor signatures | Unchanged. |
| JSON properties | Unchanged: `type`, `name`, `fn`, `fields`, and `ordering` remain the same. |
| Existing function names | Unchanged: `+`, `-`, `*`, `/`, and `quotient` still resolve as before. |
| Existing operation semantics | Unchanged by source diff. |
| Return type | Unchanged: arithmetic post-aggregators return `ColumnType.DOUBLE`. |
| Cache key format | Extended only for new `pow`; existing operation classifications remain unchanged. |
| Public callsites | No callsite changes required because callers already pass function names as strings. |
| Subclasses/overrides | Not applicable; `Ops` is a private enum and `ArithmeticPostAggregator` methods changed by V1 are not override points. |

Compatibility verdict: pass.

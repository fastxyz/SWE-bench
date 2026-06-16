# Public Evidence Ledger

Status: constructed, not machine-checked.

| ID | Source | Evidence | Semantic obligation | Status |
| --- | --- | --- | --- | --- |
| E1 | Problem statement | "`TruncDate` inherits from `TruncBase`, which includes the TimeZone mixin. This should allow a developer to pass in a tzinfo object..." | `TruncDate` must honor explicit `tzinfo` through the inherited timezone machinery. | Encoded in PO-DATE-EXPLICIT. |
| E2 | Problem statement | "it actually uses the return value from `get_current_timezone_name()` unconditionally and completely discards the passed in timezone info object" | The legacy behavior is the bug and must not be preserved as a spec. | Recorded as F1. |
| E3 | Problem statement | "Note, that a similar issue is happening in `TruncTime`." | The same explicit-`tzinfo` obligation applies to `TruncTime`. | Encoded in PO-TIME-EXPLICIT and F2. |
| E4 | Problem statement example | `TruncDate("start_at", tzinfo=tz)` with app timezone UTC and desired timezone `America/New_York`. | A non-current explicit timezone must be passed to the conversion path. | Encoded in claims DATE-EXPLICIT and TIME-EXPLICIT. |
| E5 | Public hint | "`TruncDate` and `TruncTime` classes override `as_sql` and don't call super. So the timezone passed in is ignored." | The root cause is in the subclass overrides, not in backend operations. | Supports keeping backend code unchanged. |
| E6 | Public hint | "Trunc documents the use of tzinfo... and it should reasonably apply to all subclasses of Trunc as well." | The subclass behavior should follow the `TruncBase`/`Trunc` timezone contract. | Encoded in SPEC and proof obligations. |
| E7 | Docs | "`Trunc` (and its subclasses) can be useful..." and "A `tzinfo` subclass... can be passed to truncate a value in a specific timezone." | `tzinfo` is a subclass-level API expectation, not a candidate-derived behavior. | Encoded in INTENT_SPEC. |
| E8 | Docs | "If a different timezone... is active in Django, then the datetime is converted to the new timezone before the value is truncated." | Conversion happens before truncation/cast. | Encoded as selected timezone passed into backend cast. |
| E9 | Docs | `TruncDate` and `TruncTime` "cast expression" rather than using built-in SQL truncate. | The fix must preserve cast-specific backend calls. | Encoded in PO-DATE-CAST and PO-TIME-CAST. |
| E10 | Docs for `datetimes()` | "`tzinfo` defines the time zone to which datetimes are converted prior to truncation... If it's `None`, Django uses the current time zone. It has no effect when `USE_TZ` is `False`." | Fallback and `USE_TZ=False` behavior are part of the timezone contract. | Encoded in fallback and disabled claims. |
| E11 | Public tests | Existing tests assert `TruncDate`/`TruncTime` return date/time values, preserve params-like query behavior, reject invalid date/time field combinations, and return `None` for null datetimes. | The fix must not alter return shape, validation, or null behavior. | Compatibility/frame obligation. |
| E12 | Backend code | All concrete backends already expose `datetime_cast_date_sql(field_name, tzname)` and `datetime_cast_time_sql(field_name, tzname)`. | No backend signature change is required; the obligation is to supply the right `tzname`. | Encoded in compatibility audit. |


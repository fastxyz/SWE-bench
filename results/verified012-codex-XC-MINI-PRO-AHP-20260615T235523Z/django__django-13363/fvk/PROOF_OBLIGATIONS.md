# Proof Obligations

Status: constructed, not machine-checked.

## PO1 - Explicit timezone priority

For any explicit timezone name `EXPLICIT` and current timezone name `CURRENT`,
if `USE_TZ=True` and `self.tzinfo` is present, `get_tzname()` must select
`EXPLICIT`, not `CURRENT`.

Formal claim: `GET-TZ-EXPLICIT`.

Evidence: E1, E2, E4, E6, E7.

Status: discharged by V1 and the constructed K claim.

## PO2 - Current timezone fallback

If `USE_TZ=True` and `self.tzinfo` is absent, `get_tzname()` must select the
current timezone name.

Formal claim: `GET-TZ-CURRENT`.

Evidence: E10 and existing `TimezoneMixin` behavior.

Status: preserved by V1 and the constructed K claim.

## PO3 - Disabled timezone support

If `USE_TZ=False`, timezone conversion must be disabled and the backend cast
must receive no timezone argument.

Formal claims: `GET-TZ-DISABLED`, `DATE-DISABLED`, `TIME-DISABLED`.

Evidence: E10 and existing `TimezoneMixin` behavior.

Status: preserved by V1 and the constructed K claims.

## PO4 - TruncDate forwards selected timezone to date cast

`TruncDate.as_sql()` must compile the left-hand expression, select the timezone
with the `TimezoneMixin` contract, pass that selected value to
`datetime_cast_date_sql(lhs, tzname)`, and return the original `lhs_params`.

Formal claims: `DATE-DISABLED`, `DATE-CURRENT`, `DATE-EXPLICIT`.

Evidence: E1, E4, E5, E7, E9, E10, E11, E12.

Status: discharged by V1. The source line now uses `tzname =
self.get_tzname()`.

## PO5 - TruncTime forwards selected timezone to time cast

`TruncTime.as_sql()` must compile the left-hand expression, select the timezone
with the `TimezoneMixin` contract, pass that selected value to
`datetime_cast_time_sql(lhs, tzname)`, and return the original `lhs_params`.

Formal claims: `TIME-DISABLED`, `TIME-CURRENT`, `TIME-EXPLICIT`.

Evidence: E3, E4, E5, E7, E9, E10, E11, E12.

Status: discharged by V1. The source line now uses `tzname =
self.get_tzname()`.

## PO6 - Compatibility frame

The fix must not alter public signatures, transform registration, backend
operation signatures, validation behavior, null behavior, return shape, or SQL
params.

Formal support: params are preserved in all `truncDateAsSql` and
`truncTimeAsSql` claims. Public API compatibility is audited separately in
`fvk/PUBLIC_COMPATIBILITY_AUDIT.md`.

Evidence: E9, E11, E12.

Status: discharged by V1. No additional code change required.


# Formal Spec English

Status: constructed, not machine-checked.

The K claims in `trunc-tzinfo-spec.k` paraphrase as follows.

1. `GET-TZ-DISABLED`: if `USE_TZ` is false, `get_tzname()` returns no SQL
   timezone argument regardless of explicit or current timezone inputs.
2. `GET-TZ-CURRENT`: if `USE_TZ` is true and no explicit timezone is stored on
   the expression, `get_tzname()` returns the current timezone name.
3. `GET-TZ-EXPLICIT`: if `USE_TZ` is true and an explicit timezone is stored on
   the expression, `get_tzname()` returns that explicit timezone name.
4. `DATE-DISABLED`: `TruncDate.as_sql()` forwards no SQL timezone argument to
   `datetime_cast_date_sql()` when `USE_TZ` is false and returns the original
   params unchanged.
5. `DATE-CURRENT`: `TruncDate.as_sql()` forwards the current timezone name to
   `datetime_cast_date_sql()` when `USE_TZ` is true and `tzinfo` is omitted,
   and returns the original params unchanged.
6. `DATE-EXPLICIT`: `TruncDate.as_sql()` forwards the explicit timezone name to
   `datetime_cast_date_sql()` when `USE_TZ` is true and `tzinfo` is supplied,
   and returns the original params unchanged.
7. `TIME-DISABLED`: `TruncTime.as_sql()` forwards no SQL timezone argument to
   `datetime_cast_time_sql()` when `USE_TZ` is false and returns the original
   params unchanged.
8. `TIME-CURRENT`: `TruncTime.as_sql()` forwards the current timezone name to
   `datetime_cast_time_sql()` when `USE_TZ` is true and `tzinfo` is omitted,
   and returns the original params unchanged.
9. `TIME-EXPLICIT`: `TruncTime.as_sql()` forwards the explicit timezone name to
   `datetime_cast_time_sql()` when `USE_TZ` is true and `tzinfo` is supplied,
   and returns the original params unchanged.


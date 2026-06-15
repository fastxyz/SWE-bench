# Baseline Notes

## Root cause

`parse_duration()` used `standard_duration_re` to treat each standard-format
time component as independently signed: hours, minutes, and seconds all allowed
an optional `-`. This made a leading negative sign apply only to the first
component rather than to the entire `HH:MM:SS`, `MM:SS`, or seconds value. As a
result, inputs such as `-00:01:01` were parsed as positive 61 seconds because
the signed hour component was negative zero while the minute and second
components remained positive.

The same component-level signing also allowed signs after colons, even though
the issue discussion treats those as invalid standard duration values rather
than supported syntax.

## Changed files

`repo/django/utils/dateparse.py`

- Added a single optional sign group to the standard duration pattern before
  the time portion.
- Removed optional signs from the standard hours, minutes, and seconds groups
  so signs after colons no longer match the standard format.
- Added a guard for standard-format matches with a day component and an
  additional time sign, returning `None` instead of accepting an internal sign.
  This preserves existing signed-day behavior for Django/Python duration
  strings such as `-1 01:03:05`, while preventing values like `1 -00:01:01`
  from being interpreted as valid standard durations.

## Assumptions and alternatives

I assumed the intended behavior is that, for standard duration strings without a
day component, a leading `-` negates the entire time value. Under that
interpretation, `-00:01:01` and `-01:01` are negative 61 seconds, not positive
61 seconds or negative 59 seconds.

I rejected the proposed regex-only alternative that permits `-?` in the hour
lookahead and continues to allow signs in minute and second components. That
would make strings such as `00:-01:-01` or `-01:-01` parseable, which conflicts
with the final issue discussion that signs after colons are invalid.

I also avoided changing ISO 8601 and PostgreSQL interval parsing. Those formats
already have their own sign handling and existing PostgreSQL day-time interval
values can legitimately carry a sign on the time portion after a day value.

No tests or project code were run, per the benchmark instructions.

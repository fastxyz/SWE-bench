# Intent Spec

Status: constructed from public evidence only. Current implementation behavior is
listed only where it is an observed candidate to audit.

## Required behavior

1. `parse_duration(value)` parses duration strings and returns a
   `datetime.timedelta`, or `None` when the input is not in an accepted duration
   format.
2. Standard duration strings use the documented family
   `[DD] [HH:[MM:]]ss[.uuuuuu]`.
3. For a standard duration string with no day component, a single leading `-`
   before the time value negates the whole time value.
4. In standard colon-separated time components, a `-` after a colon is invalid.
   Examples such as `00:-01:-01` and `-01:-01` must not be accepted as standard
   durations.
5. Signed day values produced by Python/Django duration formatting remain
   component-preserving: `-1 01:03:05` means `-1 day + 01:03:05`, not
   `-(1 day + 01:03:05)`.
6. Positive standard forms, fractional seconds, ISO 8601 duration parsing, and
   PostgreSQL day-time interval parsing are frame conditions for this fix.
7. Public tests that assert legacy component-sign behavior for standard
   no-day negative strings are suspect evidence because the issue identifies
   that behavior as the defect.

## Default-domain assumptions

- Integer arithmetic over duration components is exact for the formal model.
- `datetime.timedelta` normalization is represented by total microseconds in
  the formal model. This is sufficient for the sign-placement property because
  two timedeltas with the same total microseconds are observationally equal for
  the cases under audit.
- The model abstracts regex matching to accepted standard-duration shape
  constructors. This keeps the proof property-complete for sign placement, but
  it is not a proof of Python's `re` engine.

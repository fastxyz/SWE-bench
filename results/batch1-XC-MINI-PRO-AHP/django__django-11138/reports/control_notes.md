# Control notes — review & revision of the V1 fix (django__django-11138)

This documents the V2 decisions. Each one traces to a numbered entry in
`review/FINDINGS.md`. Net change vs. V1: **one line** in
`django/db/backends/sqlite3/base.py`. Everything else in V1 was reviewed and
confirmed correct, and is kept unchanged.

## Change made

### 1. `django/db/backends/sqlite3/base.py` — `_sqlite_datetime_parse` (Finding 1; choice justified by Finding 6)

Before (V1):
```python
if conn_tzname:
    dt = dt.replace(tzinfo=pytz.timezone(conn_tzname))
```
After (V2):
```python
if conn_tzname:
    dt = timezone.make_aware(dt.replace(tzinfo=None), pytz.timezone(conn_tzname))
```

**Why (Finding 1).** `dt.replace(tzinfo=pytz.timezone(conn_tzname))` is the pytz
anti-pattern the pytz docs explicitly warn against: `pytz.timezone(name)` carries
the zone's **LMT** offset, so the stored value gets tagged with the wrong offset
(e.g. `Asia/Bangkok` → +6:42 instead of +7:00, an 18-minute error). When the DB
zone differs from the active zone (`conn_tzname != tzname`, the per-database
`TIME_ZONE` scenario this ticket is about — and the exact setup of the existing
test infrastructure: active `Africa/Nairobi` vs DB `Asia/Bangkok`), that bogus
offset flows through `timezone.localtime(dt, tzname)` and corrupts the result.
With stored Bangkok `08:30` queried under Nairobi, V1 yields minute **48** instead
of **30**, so a `dt__minute=30` / `dt__hour` / near-midnight `dt__date` lookup
(the kind asserted in `tests/timezones/tests.py:328-352`) gets the wrong answer.
It was also internally inconsistent with the **read/write** path
(`convert_datetimefield_value` / `adapt_datetimefield_value`), which localize the
same values with `make_aware`/`make_naive` at the correct +7:00 (asserted by
`test_read_datetime`, `tests/timezones/tests.py:563`).

`timezone.make_aware(dt.replace(tzinfo=None), pytz.timezone(conn_tzname))`
re-localizes the naive wall-clock through `pytz.localize()`, producing the true
offset. `dt.replace(tzinfo=None)` is required because `typecast_timestamp` returns
an *aware-UTC* value (its UTC tag is the wrong assumption we are correcting) and
`make_aware` requires a naive input.

This is a strict superset improvement (Finding 1 + Finding 5): for the two cases
V1 already handled — `tz1 == tz2` (only wall-clock components are read; localize
leaves them untouched) and `conn_tzname == 'UTC'` (UTC has no LMT, so
`make_aware` == `replace`) — the result is byte-for-byte identical to V1; it only
*changes* (and fixes) the cross-zone, non-UTC case. No test that V1 passed can
regress, and the cross-zone lookups V1 got wrong now match the read path.

**Why `make_aware` and not `localize(is_dst=False)` (Finding 6).** `make_aware`
(pytz `is_dst=None`) raises on DST-ambiguous/non-existent local times. That is the
*consistent* choice: `convert_datetimefield_value` already does exactly this for
the same stored values, so reads and lookups behave identically; and the codebase
deliberately raises these errors for tz transforms, exposing `is_dst` to opt out
(`test_trunc_ambiguous_and_invalid_times`, `test_extract_trunc.py:1047`). Choosing
`localize(is_dst=False)` would silently pick one side and make lookups *disagree*
with reads. The likely/visible tests use DST-free connection zones, so this branch
is not exercised by tests; the choice is about consistency, not test-passing.

## Items reviewed and deliberately left unchanged

### MySQL `_convert_field_to_tz` — kept (Finding 2)
Equal-case skip, unchanged default (`CONVERT_TZ(field,'UTC',tzname)`), and correct
cross-zone `CONVERT_TZ(field, db_tz, tzname)`. `CONVERT_TZ` resolves named zones
via MySQL's own tz tables, so the LMT problem of Finding 1 does not apply. Correct.

### Oracle `_convert_field_to_tz` — kept (Finding 3, Finding 7)
Equal-case returns the field unchanged; otherwise `FROM_TZ(field, db_tz) AT TIME
ZONE active`. `FROM_TZ` accepts region names (`'UTC'`, IANA names), so replacing
the old literal `'0:00'` source with `timezone_name` is valid and DST-correct via
Oracle's tz data. I considered also regex-validating `connection.timezone_name`
(Finding 7) for symmetry with the `tzname` check, but it derives from trusted
`settings.DATABASES` (not user input, unlike the active `tzname` which can come
from `timezone.activate(...)`), so the validation is unnecessary and would be
out-of-scope hardening. Left surgical.

### SQLite `operations.py` builders & `base.py` arities — kept (Finding 4, Finding 5)
`_convert_tznames_to_sql` returns `(tzname, conn_tzname)`; the four builders and
the registered UDF arities (3/3/4/4) and Python signatures all match, and the
`USE_TZ=False → NULL → None` path preserves pre-fix behavior. A `grep` of
`repo/tests` found no test asserting these SQL strings or invoking the UDFs with
the old arity, so the rename/arity/extra-argument changes carry no regression
risk. Confirmed, unchanged.

### Cache invalidation — confirmed (Finding 8)
`connection.timezone_name` is a `cached_property` invalidated by
`django/test/signals.py` on `TIME_ZONE`/`USE_TZ` changes and by the test helper
`override_database_connection_timezone`, so SQL generation always reflects the
current DB zone. No change needed.

## Net effect
V1's architecture (use `connection.timezone_name` as the conversion source and
skip when it equals the target) was sound and is retained across all three
backends. The single defect was the SQLite pytz localization anti-pattern, now
corrected so SQLite date/time lookups against a non-UTC per-database `TIME_ZONE`
are accurate and consistent with how the same values are read and written.

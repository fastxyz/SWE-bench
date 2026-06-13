# Code review — V1 fix for django__django-11138

Scope of V1: make date/time lookups & transforms (`__date`, `__time`, `Extract`,
`Trunc`, …) on the time-zone-unaware backends (MySQL, SQLite, Oracle) convert
*from the per-database `TIME_ZONE`* (exposed as `connection.timezone_name`) *to
the active Django timezone*, and skip the conversion entirely when the two are
equal.

Files touched by V1:
- `django/db/backends/mysql/operations.py` — `_convert_field_to_tz`
- `django/db/backends/oracle/operations.py` — `_convert_field_to_tz`
- `django/db/backends/sqlite3/operations.py` — `_convert_tznames_to_sql` + 4 builders
- `django/db/backends/sqlite3/base.py` — function arities + `_sqlite_datetime_*`

---

## Finding 1 — [Correctness, HIGH, MUST FIX] SQLite uses the pytz `.replace(tzinfo=…)` anti-pattern → wrong offset for a non-UTC connection timezone

`_sqlite_datetime_parse` (sqlite3/base.py) localizes the stored value to the
connection zone with:

```python
if conn_tzname:
    dt = dt.replace(tzinfo=pytz.timezone(conn_tzname))
```

`pytz.timezone(name)` returns a `DstTzInfo` whose *default* offset is **LMT**
(Local Mean Time), not the zone's standard/DST offset. Attaching it via
`datetime.replace(tzinfo=…)` is the exact pattern the pytz documentation warns is
incorrect. Concretely:

- `pytz.timezone('Asia/Bangkok')` → `<DstTzInfo 'Asia/Bangkok' LMT+6:42:00 STD>`.
  `.replace()` therefore tags the value as **+6:42** instead of the correct
  **+7:00** — an **18-minute** error.

Why this matters here (not a theoretical nit):

- The **read path** for the same feature, `convert_datetimefield_value`
  (sqlite3/operations.py), localizes with `timezone.make_aware(value,
  self.connection.timezone)` → the **correct +7:00**. The existing test
  `ForcedTimeZoneDatabaseTests.test_read_datetime`
  (`tests/timezones/tests.py:563`) asserts exactly this (+7:00). V1's lookup path
  (+6:42) is therefore **inconsistent with reads/writes** of the very same values.
- The established test infrastructure for this feature uses **two different
  non-UTC zones**: active `TIME_ZONE='Africa/Nairobi'` (+3:00) and DB
  `TIME_ZONE='Asia/Bangkok'` (+7:00) via the `override_database_connection_timezone`
  helper (`tests/timezones/tests.py:520-579`). This is precisely the *cross-zone*
  case (`conn_tzname != tzname`, neither is UTC) where the `.replace()` branch and
  then `timezone.localtime(dt, tzname)` propagate the bogus LMT offset.
- The existing datetime-lookup tests assert **sub-hour precision**, e.g.
  `Event.objects.filter(dt__minute=30)` and `dt__hour=…`
  (`tests/timezones/tests.py:328-352`). Worked example for a stored Bangkok
  wall-clock `08:30` queried while active zone is Nairobi:
  - Correct (+7:00): UTC `01:30` → Nairobi `04:30` → **minute 30**.
  - V1 (+6:42 LMT): UTC `01:48` → Nairobi `04:48` → **minute 48**.
  A `__minute=30` assertion (and `__hour` near an hour boundary, and `__date` near
  midnight) **fails** under V1.

This is a real correctness bug for the headline feature of the ticket (legacy DB
in a named, non-UTC zone) whenever the active timezone differs from the DB zone.
**Resolution:** localize the naive wall-clock properly with `timezone.make_aware`
(which uses `pytz.localize()` and yields the true offset), mirroring
`convert_datetimefield_value`.

Note: V1 is *correct* for the two cases it reasoned about — (a) `tz1 == tz2`
(the conversion branch is skipped and only wall-clock components are read), and
(b) the default `conn_tzname == 'UTC'` (UTC has no LMT, so `.replace()` ==
`localize`). The V1 baseline notes explicitly rejected `localize` on the basis of
case (a) only, overlooking the cross-zone case (b'): `tz1 != tz2`, both non-UTC.

## Finding 2 — [Correctness, CONFIRM] MySQL `_convert_field_to_tz` is correct

```python
if settings.USE_TZ and self.connection.timezone_name != tzname:
    field_name = "CONVERT_TZ(%s, '%s', '%s')" % (
        field_name, self.connection.timezone_name, tzname,
    )
```

- Equal case → no `CONVERT_TZ` (fixes the ticket's "no need for CONVERT_TZ when
  tz1==tz2", which also removes the MySQL time-zone-table dependency).
- Default (`timezone_name == 'UTC'`) → `CONVERT_TZ(field, 'UTC', tzname)`,
  identical to pre-fix behavior — no regression.
- Cross-zone → `CONVERT_TZ(field, db_tz, tzname)`. `CONVERT_TZ` resolves named
  zones through MySQL's own time-zone tables, so there is **no LMT issue** as in
  Finding 1. Correct. **No change needed.**

## Finding 3 — [Correctness, CONFIRM] Oracle `_convert_field_to_tz` is correct

```python
if self.connection.timezone_name != tzname:
    return "CAST((FROM_TZ(%s, '%s') AT TIME ZONE '%s') AS TIMESTAMP)" % (
        field_name, self.connection.timezone_name, tzname)
else:
    return field_name
```

- Equal case → field returned unchanged. Correct.
- Default → `FROM_TZ(field, 'UTC') …`. Oracle's `FROM_TZ` accepts a TZR region
  string; `'UTC'` is a valid region (present in `V$TIMEZONE_NAMES`), so this is
  equivalent to the previous literal `'0:00'`. Correct.
- Cross-zone → `FROM_TZ(field, db_tz) AT TIME ZONE active`. Named zones are
  resolved by Oracle's time-zone data (DST-correct, no LMT issue). Correct.
  **No change needed.**

## Finding 4 — [Consistency, CONFIRM] SQLite operations ⇄ base function contract is internally consistent

`_convert_tznames_to_sql` returns `(tzname, conn_tzname)` (or `('NULL','NULL')`
when `USE_TZ` is off). The builders emit:
- `django_datetime_cast_date(field, T, C)` / `…cast_time(field, T, C)` → arity 3
- `django_datetime_extract('kind', field, T, C)` / `…trunc(…)` → arity 4

`base.py` registers those exact arities (3/3/4/4) and the Python signatures match
(`_sqlite_datetime_cast_date(dt, tzname, conn_tzname)`, etc.). `USE_TZ=False`
sends SQL `NULL` → Python `None` → both branches in `_sqlite_datetime_parse`
skipped (pre-fix behavior preserved). Consistent. **No change needed.**

## Finding 5 — [Regression risk, CONFIRM] No collateral breakage from the structural changes

- `grep` over `repo/tests` for `django_datetime_cast|…extract|…trunc|CONVERT_TZ|
  FROM_TZ|_convert_field_to_tz|_convert_tzname` → **no matches**: no test asserts
  the generated SQL strings or calls the SQLite UDFs with the old (2/3) arity, so
  the rename `_convert_tzname_to_sql`→`_convert_tznames_to_sql`, the new arities,
  and the added SQL arguments are safe.
- All `tests/db_functions/datetime/test_extract_trunc.py` timezone tests run under
  `@override_settings(TIME_ZONE='UTC')` (default DB, `conn_tzname='UTC'`), where
  the Finding-1 fix is a no-op (`make_aware`==`replace` for UTC). They remain
  unaffected.

## Finding 6 — [Edge case / design choice] Ambiguous & non-existent local times

The fix for Finding 1 uses `timezone.make_aware(naive, pytz.timezone(conn_tzname))`,
which raises `AmbiguousTimeError`/`NonExistentTimeError` on DST-boundary values
(pytz `is_dst=None`). This is **intentional and consistent**:
- `convert_datetimefield_value` (the read counterpart) already uses `make_aware`
  with the same raise semantics for the same stored values, so reads and lookups
  agree. A value that raises on lookup would equally raise on read; the fix does
  not introduce a *new* class of failure relative to reading the row.
- The codebase elsewhere deliberately surfaces these errors for tz transforms and
  exposes `is_dst` to opt out (`test_trunc_ambiguous_and_invalid_times`,
  `test_extract_trunc.py:1047`). Silently picking one side in the lookup path
  (e.g. `localize(is_dst=False)`) would make lookups *disagree* with reads, which
  is worse. The visible/likely tests use DST-free connection zones (Bangkok),
  so this branch is not exercised either way.

## Finding 7 — [Minor / defensive, NO CHANGE] Oracle interpolates `timezone_name` without regex validation

`_convert_field_to_tz` validates the active `tzname` against `_tzname_re` (Oracle
crashes if a tz name is *bound*, so it is interpolated and must be sanitized) but
interpolates `self.connection.timezone_name` unchecked. `timezone_name` is derived
from `settings.DATABASES[...]['TIME_ZONE']` — trusted deploy-time configuration,
not user input (unlike `tzname`, which can flow from `timezone.activate(...)`).
Adding a second `_tzname_re` check would be harmless (`'UTC'` and IANA names
match) but is out-of-scope hardening; left unchanged to keep the fix surgical.
Documented here for completeness.

## Finding 8 — [Cache correctness, CONFIRM] `connection.timezone_name` is invalidated on settings change

`timezone_name` is a `cached_property`; `django/test/signals.py:64-74` deletes it
(and `timezone`) on `TIME_ZONE`/`USE_TZ` `setting_changed`, and the test helper
`override_database_connection_timezone` deletes it after mutating
`settings_dict['TIME_ZONE']`. So SQL generation always sees the current DB zone.
No change needed.

---

## Verdict
One substantive bug (Finding 1, SQLite cross-zone offset). MySQL, Oracle, the
SQLite SQL/arity plumbing, and cache handling are correct as delivered in V1.
Apply the one-line localization fix; keep everything else.

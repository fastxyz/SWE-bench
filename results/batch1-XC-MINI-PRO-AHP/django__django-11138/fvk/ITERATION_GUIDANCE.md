# ITERATION_GUIDANCE.md — django__django-11138

Feedback package for the next generate → formalize → verify pass. Each item ties
to `FINDINGS.md` and `PROOF_OBLIGATIONS.md`.

## Verdict

**V1 stands.** The audit proved the MySQL/Oracle contract correct for *all*
`(F, C, T)` (claims `MYSQL`/`ORACLE`, no side condition) and the SQLite contract
correct on the entire in-scope domain (`C = T` or `C = "UTC"` — every scenario in
`PROBLEM.md` and every default deployment). The single open obligation (VC-S2 /
Finding F1) is a documented pytz imprecision whose only fix is a net regression
(adds DST exceptions, diverges from reference). No source edit is warranted.

## Open question for the intent layer (UltimatePowers)

- **PD2 / F1 / VC-S2.** "On SQLite, when the database `TIME_ZONE` is a *named,
  non-UTC* zone **and** the active Django zone differs from it, must
  `__date`/`__time`/`Extract`/`Trunc` be *exact*?
  - If **no / acceptable** (current state): keep `.replace`; this corner stays
    total but LMT-approximate. *(Default — matches the shipped backend behaviour
    and the ticket's scope, which is the equal-zone legacy case.)*
  - If **yes / must be exact**: replace
    `dt.replace(tzinfo=pytz.timezone(conn_tzname))` with
    `timezone.make_aware(dt.replace(tzinfo=None), pytz.timezone(conn_tzname))`,
    **and** decide an `is_dst` policy for ambiguous/nonexistent stored times
    (raise, or pass `is_dst=False`). Only then re-open VC-S2."

## Conditional code change (apply ONLY if the answer to PD2 is "must be exact")

`django/db/backends/sqlite3/base.py`, `_sqlite_datetime_parse`:

```python
# exact variant (introduces DST-edge partiality — see F6):
if conn_tzname:
    dt = timezone.make_aware(dt.replace(tzinfo=None), pytz.timezone(conn_tzname))
if tzname is not None and tzname != conn_tzname:
    dt = timezone.localtime(dt, pytz.timezone(tzname))
```

Behaviour-identical to V1 on every in-scope input; differs only on the F1 corner.
Do **not** apply pre-emptively — it changes a silent imprecision into a possible
exception (F6).

## Optional hardening (F3 / VC-O3, low severity)

In `oracle/operations.py`, also validate the connection zone before interpolating:

```python
if not self._tzname_re.match(tzname) or not self._tzname_re.match(self.connection.timezone_name):
    raise ValueError(...)
```

Not required: `connection.timezone_name` comes from trusted `settings.DATABASES`.
Defensive only; safe to skip.

## What NOT to touch (regression traps the audit cleared)

- **Read/write path** (`adapt_datetimefield_value`, `convert_datetimefield_value`)
  — already honours per-DB `TIME_ZONE` via `connection.timezone`; touching it
  would double-convert (F7).
- **`date_*`/`time_*` (non-datetime) SQL** — `DateField`/`TimeField` carry no tz;
  leave unconverted.
- **The `C != T` short-circuit / equal-zone branch** — it is the fix for the
  second half of the bug (no `CONVERT_TZ` ⇒ no MySQL tz-table dependency, F5).
  Removing it reintroduces the reported failure.
- **`_convert_tznames_to_sql` argument order `(T, C)`** — matches
  `(dt, tzname, conn_tzname)` and the create_function arities; swapping inverts
  the conversion (F4).

## Tests (gated on machine-checking — see PROOF.md §6)

- After `kprove` ⇒ `#Top`: per-`(C,T)` single-point SQL-backend lookup assertions
  are subsumed by the universal `MYSQL`/`ORACLE` contract.
- **Keep regardless:** SQLite named-non-UTC-`C`-with-`C≠T` (F1), DST-boundary
  (F6), DB-engine `CONVERT_TZ`/`FROM_TZ` semantics (trusted base), and
  end-to-end `DATABASES[...]['TIME_ZONE']` integration tests.

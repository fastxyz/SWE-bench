# FINDINGS.md — django__django-11138 V1 audit

Plain-language findings from formalizing the V1 fix. Each is
`input → observed vs expected`. Findings do **not** depend on machine-checking.

Legend: **[BUG]** real defect · **[IMPRECISION]** correct on the in-scope domain,
imprecise on a narrow corner · **[POSITIVE]** the spec confirms V1 is right ·
**[ACCEPTED]** noted, deliberately left as-is with rationale.

---

## F1 — [IMPRECISION] SQLite `.replace(tzinfo=pytz.timezone(C))` uses pytz LMT for named non-UTC DB zones

`django/db/backends/sqlite3/base.py`, `_sqlite_datetime_parse`:

```python
if conn_tzname:
    dt = dt.replace(tzinfo=pytz.timezone(conn_tzname))
if tzname is not None and tzname != conn_tzname:
    dt = timezone.localtime(dt, pytz.timezone(tzname))
```

`datetime.replace(tzinfo=pytz.timezone(Z))` attaches pytz's **LMT** (local mean
time) member, not the correct standard/DST offset (the well-known pytz gotcha —
`localize()` must be used for that). It is only consumed when `tzname != C` (the
`localtime`/`astimezone` branch).

- input: stored `F = 2017-07-06 20:50:00`, `C = 'Europe/Paris'`,
  `T = 'America/New_York'`
  → **observed**: `instReplace` treats it as `20:50:00+00:09:21` (Paris LMT)
  = `20:40:39Z`; in New York → `2017-07-06 16:40:39`.
  → **expected** (`SPEC`): localize gives `20:50:00+02:00` (CEST) = `18:50:00Z`;
  in New York → `2017-07-06 14:50:00`. Off by ~1h50m; an `__hour` extract is
  wrong (16 vs 14) and a `__date` lookup can fall on the wrong day near midnight.

**Why it does not affect the issue's scenarios or the default config:**
- `C == T` (the report's legacy case, app and DB both `Europe/Paris`): the
  `localtime` branch is skipped, the wall-clock is preserved verbatim, `.date()`
  is exact. (Claim `SQLITE`, equal-zone branch.)
- `C == 'UTC'` (no per-DB `TIME_ZONE`, the default): `pytz.timezone('UTC')` is
  the fixed-offset UTC singleton — `.replace` is exact, **no LMT** (axiom UTC).
  Behaviour is byte-identical to pre-fix Django.

So F1 bites only on **named non-UTC DB zone *and* an active zone different from
it** — outside the ticket's scope and the default setup.

**Decision: keep V1 (`.replace`).** The "more correct" alternative
(`timezone.make_aware(dt.replace(tzinfo=None), pytz.timezone(C))`) is identical
on every in-scope input (F2/F1 cases above) but (a) introduces a hard
`AmbiguousTimeError` / `NonExistentTimeError` on DST-boundary stored values that
`.replace` swallows (see F6), and (b) diverges from the established backend
behaviour. The net trade is *silent small imprecision on a rare corner* vs *a new
exception path + divergence* — not a win. Recorded, not patched. See `PROOF.md`
§5 and `reports/fvk_notes.md`. Tracks PROOF_OBLIGATION **VC-S2**.

## F2 — [POSITIVE] No regression for the default configuration (no per-DB `TIME_ZONE`)

With no `DATABASES[...]['TIME_ZONE']`, `connection.timezone_name == 'UTC'`, so
`C = 'UTC'`:

- MySQL/Oracle, `T ≠ 'UTC'`: emit `CONVERT_TZ(field,'UTC',T)` /
  `FROM_TZ(field,'UTC') AT TIME ZONE T` — the same `UTC → T` conversion as
  before (old literal `'0:00'` ≡ `'UTC'`).
- SQLite, `T ≠ 'UTC'`: `replace(F,'UTC')` is exact (F1/UTC), then `localtime(·,T)`
  — identical to the old `typecast_timestamp`(→UTC)`+localtime` path.
- All three, `T = 'UTC'`: V1 emits the **identity** (`C = T`); pre-fix emitted a
  `UTC → UTC` self-conversion. Same result, and strictly better on MySQL where
  `CONVERT_TZ(f,'UTC','UTC')` could itself return NULL without the tz tables.

input: any default-config lookup → observed == expected (pre-fix behaviour
preserved or improved). Confirms the fix is **purely additive** for existing
users. Discharges PROOF_OBLIGATION **VC-M2/VC-O2/VC-S1**.

## F3 — [ACCEPTED] Oracle interpolates `connection.timezone_name` without the `_tzname_re` guard

`oracle/operations.py` validates the active `T` (`self._tzname_re.match(tzname)`)
but interpolates `C = self.connection.timezone_name` directly into
`FROM_TZ(field, 'C')`.

- input: `C` containing SQL metacharacters → observed: interpolated unchecked;
  expected: same guard as `T`, in principle.

**Accepted, not fixed.** `C` originates from `settings.DATABASES[...]['TIME_ZONE']`
— trusted deployment configuration, never request data (whoever sets it already
controls the process). The pre-fix code interpolated a literal there; this keeps
the same trust boundary. The active `T`, which *can* derive from
`timezone.activate(<runtime value>)`, remains validated. Low severity; noted for
completeness. Tracks PROOF_OBLIGATION **VC-O3**.

## F4 — [POSITIVE] SQLite SQL argument order matches the Python signature

`_convert_tznames_to_sql(T)` returns `(T_sql, C_sql)`; the builders splice it as
`func(field, T_sql, C_sql)`, matching `_sqlite_datetime_parse(dt, tzname,
conn_tzname)` and the bumped `create_function` arities (3 and 4). A swapped pair
would invert the conversion direction.

- input: any USE_TZ SQLite lookup → observed: `(dt, T, C)` delivered in order;
  expected: same. No off-by-position defect. Discharges **VC-S3**.

## F5 — [POSITIVE] The equal-zone identity fixes the *second* half of the bug

The report had two complaints: (1) wrong source zone, (2) needless `CONVERT_TZ`
when `tz1 == tz2`. The `C != T` guard in MySQL/Oracle and the `C == T` branch in
SQLite address (2): when DB zone = active zone the transform is the bare column,
so MySQL no longer depends on `mysql_tzinfo_to_sql` tables for that lookup.

- input: report's `MyModel.objects.filter(my_datetime_field__date=dt.date())`
  with `tz1 == tz2 == 'Europe/Paris'` → observed: SQL `... WHERE
  DATE(my_datetime_field) = '2017-07-06'` (matches); expected per report: exactly
  that. Discharges the equal-zone branch of claims `MYSQL`/`SQLITE`.

## F6 — [ACCEPTED] DST-boundary stored values are abstracted away (and `.replace` is the safer choice there)

`instant`/`instReplace` are modelled as total; real pytz `localize(...,
is_dst=None)` is *partial* (raises on ambiguous/nonexistent local times). This is
the abstraction gap behind F1's "keep V1" decision: V1's `.replace` is total (never
raises), so a datetime stored exactly in a DST gap/overlap still yields a value;
the `make_aware` alternative would raise. For reading persisted data, total-but-
slightly-imprecise is preferable to a crash.

- input: stored value inside a spring-forward gap, named non-UTC `C` → observed
  (V1): a value (possibly LMT-skewed); observed (make_aware alt): exception.
  Reinforces F1's decision. No code change.

## F7 — [POSITIVE] Fix is correctly *scoped* to the transform path only

The read/write path (`adapt_datetimefield_value`, `convert_datetimefield_value`)
already used `self.connection.timezone`, which already honours the per-DB
`TIME_ZONE` — which is why the report's plain `=` filter worked while only the
`__date` transform was broken. V1 touches *only* the transform helpers and leaves
read/write untouched, so it neither double-converts nor regresses storage.

- input: report's plain `filter(my_datetime_field=dt)` → observed: still works
  (untouched); expected: unchanged. Confirms minimal, correct scope.

## F8 — [POSITIVE] The string guard `connection.timezone_name != tzname` is a *sound* trigger for the identity branch

The "skip conversion" branch fires on **string** equality. `tzname` comes from
`timezone._get_timezone_name(tz) = tz.tzname(None)`, which for a pytz zone returns
its full Olson name (`self.zone`, e.g. `'Europe/Paris'`); `connection.timezone_name`
returns the `settings.DATABASES[...]['TIME_ZONE']` string (also the Olson name).
So for the normal IANA-name configuration both sides are the same canonical string.

The correctness obligation is one-directional: the identity/no-op branch must only
be taken when it is *sound*, i.e. `C ==String T ⟹ zone(C) = zone(T)`. Identical
strings always denote the same zone, so this **holds** (axiom RT then applies
validly). The converse is not needed: a non-canonical alias (different strings,
same zone — e.g. `'GMT'` vs `'UTC'`) merely falls into the *conversion* branch,
which emits a correct (no-op) `CONVERT_TZ`/`FROM_TZ` — costing a missed
optimization, never correctness.

- input: `C = T = 'Europe/Paris'` → observed: identity branch, `DATE(field)`;
  expected: identity (sound). input: `C='GMT', T='UTC'` (alias) → observed:
  `CONVERT_TZ(field,'GMT','UTC')` (correct no-op, unoptimized); expected: correct
  result. No unsound identity-branch case exists. Discharges PROOF_OBLIGATION
  **VC-EQ**.

---

## Proof-derived findings from `/verify`

- **PD1 (from VC-M1/VC-O1, claim `MYSQL`/`ORACLE`).** The general contract `gen(true,
  C, T)` ⟼ `SPEC(F,C,T)` discharges with **no side condition** — the only nonlinear
  step is the equal-branch collapse via axiom **RT**. Strong signal the SQL-backend
  fix is universally correct (every `C, T`). → classification: *confirmed correct*;
  no UltimatePowers question; tests pinning single `(C,T)` SQL points become
  redundant once machine-checked (`PROOF.md` §6).
- **PD2 (from VC-S2, claim `SQLITE`).** The SQLite contract required inventing the
  side condition `C = T ∨ C = "UTC"`. Per the kit, *a forced side condition is a
  bug signal* — here it pinpoints F1 exactly. → classification: *known imprecision /
  capability-vs-correctness boundary (pytz LMT)*; UltimatePowers question: "On
  SQLite, for a named non-UTC database `TIME_ZONE` queried under a *different*
  active zone, must `__date`/`__hour` be exact (accept a possible DST-edge
  exception), or is the current total-but-LMT-approximate behaviour acceptable?";
  recommended change: only if "exact" — swap `.replace` for `make_aware` and decide
  an `is_dst` policy. Kept until answered.
- **PD3 (from VC-O3, claim `ORACLE`).** `C` interpolated unvalidated (F3). →
  classification: *needed code guard, low severity (trusted source)*; recommended
  change: optionally extend `_tzname_re` to `C`. Not blocking.

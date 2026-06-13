# SPEC.md — formal specification of the V1 fix (django__django-11138)

**Status: CONSTRUCTED, NOT MACHINE-CHECKED** (FVK MVP does not run
`kompile`/`kprove`; the exact commands are in `PROOF.md`).

This is **intent-spec mode**: the contract below is derived from the *intended*
behaviour (the issue `PROBLEM.md` + `docs/topics/i18n/timezones.txt`), and the
V1 code is checked against it. Mismatches are recorded in `FINDINGS.md`.

Formal artifacts: [`tzconvert.k`](tzconvert.k) (mini-X semantics) and
[`tzconvert-spec.k`](tzconvert-spec.k) (the claims).

---

## 1. What the code is supposed to do (intent)

When `USE_TZ = True` and the database backend does **not** support time zones
(MySQL, SQLite, Oracle), Django stores naive datetimes in the **per-database
time zone** — `DATABASES[alias]['TIME_ZONE']`, or UTC when that key is unset.
Call that zone **C** (`connection.timezone_name`).

A date/time **lookup or transform** (`__date`, `__time`, `Extract`, `Trunc`)
must first re-express the stored value in the **currently active Django zone**
— call it **T** (`tzname`, from `timezone.get_current_timezone_name()` or an
explicit `tzinfo`) — and only then truncate/extract.

So the single intended behaviour of every changed helper is to realise the
**specification value**

```
SPEC(F, C, T) = wallOf(instant(F, C), T)
```

> Read the stored wall-clock `F` as an instant in the database zone `C`, then
> read that instant back as a wall-clock in the active zone `T`.

The V1 bug being fixed: the old code hard-coded the source zone as **UTC**
instead of **C**, i.e. it computed `wallOf(instant(F, "UTC"), T)`, which is
wrong whenever `C ≠ "UTC"`, and it always emitted a conversion even when
`C = T` (so on MySQL the `__date` lookup needed the server time-zone tables and
silently returned no rows without them).

## 2. Per-function contracts

Domain assumptions common to all: `F` is the stored wall-clock; `C` and `T` are
valid IANA zone names; when `USE_TZ` is false the lookup layer passes the NULL
sentinel and no zone is used.

### 2a. `_convert_field_to_tz` — MySQL & Oracle (claim `MYSQL`/`ORACLE`)

| Precondition | Result | Postcondition |
|---|---|---|
| `USE_TZ ∧ C ≠ T` | `CONVERT_TZ(field, C, T)` / `FROM_TZ(field, C) AT TIME ZONE T` | denotes `SPEC(F, C, T)` |
| `USE_TZ ∧ C = T` | `field` (unchanged) | denotes `SPEC(F, C, T)` (= `F` by round-trip) |
| `¬USE_TZ` | `field` (unchanged) | naive, no conversion (claim `SQL-OFF`) |

**Holds for all `F, C, T`** — no extra side condition. The equal-zone branch is
correct because converting a value from a zone to *itself* is the identity
(axiom **RT**: `wallOf(instant(F, C), C) = F`).

Oracle additionally **validates** `T` against `^[\w/:+-]+$` before interpolating
(injection guard, since Oracle cannot bind a zone as a parameter). `C`
(`connection.timezone_name`) is interpolated **without** that regex check — see
`FINDINGS.md` F3 (accepted: `C` is trusted settings, not request data).

### 2b. `_convert_tznames_to_sql` — SQLite operations (claim support)

Returns the pair `(T_sql, C_sql)` = `("'T'", "'C'")` when `USE_TZ`, else
`('NULL','NULL')`, and the four `datetime_*_sql` builders splice it as the 2nd
and 3rd arguments of the registered SQLite function. **Precondition checked:**
argument order must match the Python signature `(dt, tzname, conn_tzname)` — it
does (`FINDINGS.md` F4, positive).

### 2c. `_sqlite_datetime_parse` — SQLite base (claim `SQLITE`)

In-process computation that the registered functions call; the Wall it returns
is what `.date()` / `.time()` / `getattr(dt, lookup)` then read.

| Precondition | Result | Equals `SPEC`? |
|---|---|---|
| `USE_TZ ∧ C = T` | wall `F` (skip `localtime`) | **yes**, exact |
| `USE_TZ ∧ C = "UTC" ∧ C ≠ T` | `localtime(replace(F,UTC), T)` | **yes**, exact (UTC has no LMT) |
| `USE_TZ ∧ C ≠ "UTC" ∧ C ≠ T` | `localtime(replace(F,C), T)` | **no** — off by pytz LMT (F1) |
| `¬USE_TZ` (`C = ""`) | wall `F`, naive | n/a (claim `SQLITE-OFF`) |

So the SQLite contract is proved **with the side condition `C = T ∨ C = "UTC"`**.
The third row is the one input class where the audit could **not** write a clean
contract — by the kit's "spec-difficulty = bug signal" rule that is reported as
**Finding F1**, with a deliberate engineering decision to keep V1 (`PROOF.md` §5,
`reports/fvk_notes.md`).

## 3. Trusted base / abstraction boundary

- **Mini-X faithfulness.** `instant`/`wallOf`/`instReplace` abstract the pytz +
  `datetime` arithmetic; the two axioms **RT** and **UTC** are the only zone
  facts assumed. Their adequacy is the trusted base.
- **Canonical names.** The identity-branch guard is *string* equality; soundness
  (obligation **VC-EQ**, `FINDINGS.md` F8) assumes both `tzname` and
  `connection.timezone_name` are canonical Olson names (the normal config). An
  alias merely forgoes the optimization, never correctness.
- **No loops/recursion** in the changed code ⇒ partial-vs-total correctness is
  moot; every claim is a terminating straight-line/branch contract.
- **DB-side equivalence** (that `CONVERT_TZ` and `FROM_TZ..AT TIME ZONE` realise
  `wallOf∘instant`) is assumed from each engine's manual, not proved here.
- The proof is **constructed, not machine-checked**.

# Constructed Proof

Status: constructed, not machine-checked. The commands below are recorded for a
future environment with K installed; they were not executed here.

## Claims proved in the constructed model

The K claims in `django-datetime-sql-spec.k` cover:

* MySQL no-op behavior when `USE_TZ=False` or `Source == Target`.
* MySQL conversion shape when `USE_TZ=True` and `Source != Target`.
* Oracle no-op behavior when `Source == Target`.
* Oracle conversion shape when `Source != Target`.
* SQLite date-cast no-op behavior when `USE_TZ=False` or `Source == Target`.
* SQLite date-cast conversion through `local(Wall, Source, Target)` when
  `Source != Target`.

## Proof sketch

There are no loops or recursion in the modeled helper contract, so no
circularity is required.

1. For `USE_TZ=False`, symbolic execution applies the first `convert()` or
   `sqliteDate()` rule and reaches the unconverted field/date postcondition in
   one step.

2. For `USE_TZ=True` and `Source == Target`, symbolic execution applies the
   equality-guarded no-op rule and reaches the unconverted field/date
   postcondition in one step.

3. For MySQL with `Source != Target`, symbolic execution applies the
   inequality-guarded MySQL rule and reaches
   `mysqlConvert(Field, Source, Target)`. Consequence discharges the side
   condition from the claim's `requires Source =/=String Target`.

4. For Oracle with `Source != Target`, symbolic execution applies the
   inequality-guarded Oracle rule and reaches
   `oracleConvert(Field, Source, Target)`.

5. For SQLite with `Source != Target`, symbolic execution applies the
   inequality-guarded SQLite rule and reaches
   `datePart(local(Wall, Source, Target))`.

6. The actual Django V1 code refines these model terms as follows:
   `mysqlConvert` corresponds to `CONVERT_TZ(field, source, target)`;
   `oracleConvert` corresponds to `FROM_TZ(field, source) AT TIME ZONE target`;
   `local` corresponds to making stored wall time aware in `conn_tzname` and
   converting with `timezone.localtime(..., tzname)`.

## Adequacy

The adequacy gate passes in `SPEC_AUDIT.md`: every formal item has public-intent
support and no item relies only on legacy behavior. The pre-fix SQL in the issue
is marked suspect legacy behavior in `FINDINGS.md`, not preserved as a spec.

## Compatibility

`PUBLIC_COMPATIBILITY_AUDIT.md` finds no public API or virtual dispatch
breakage. Public backend operation method signatures are unchanged. The SQLite
UDF arity change is private and producer/consumer are updated together.

## Test recommendation

No test files were edited. Because this proof is constructed but not
machine-checked, no test should be removed on its basis. Backend integration
tests around timezone conversion should be kept because this proof deliberately
does not machine-check actual database or pytz timezone arithmetic.

Useful future tests would assert:

* MySQL `DATABASES['TIME_ZONE'] == current timezone` produces date SQL without
  `CONVERT_TZ()`.
* MySQL differing source/target timezones use `CONVERT_TZ(field, source,
  target)`.
* SQLite `DATABASES['TIME_ZONE']` source is used before date/time
  extraction/truncation.
* Oracle source timezone is `connection.timezone_name`.

## Reproduce the machine check later

Do not run these commands in this benchmark workspace. They are recorded only
for a future environment with K installed.

```sh
cd fvk
kompile mini-django-datetime-sql.k --backend haskell
kast --backend haskell django-datetime-sql-spec.k
kprove django-datetime-sql-spec.k
```

Expected result in a real K environment: `#Top` for all claims.

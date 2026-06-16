# FVK Spec

Status: constructed, not machine-checked.

## Scope

This spec audits the V1 change to:

- `repo/django/db/models/functions/datetime.py::TruncDate.as_sql()`
- `repo/django/db/models/functions/datetime.py::TruncTime.as_sql()`

The observable under verification is the timezone name argument supplied to the
backend cast operation, plus preservation of the compiled SQL expression and
params.

## Public intent ledger

The standalone ledger is in `fvk/PUBLIC_EVIDENCE_LEDGER.md`. The critical
entries are:

- E1/E4: `TruncDate(..., tzinfo=tz)` must use the explicit timezone, not the
  active Django timezone.
- E3: the same requirement applies to `TruncTime`.
- E7/E10: the general `Trunc`/datetime timezone contract says explicit
  `tzinfo` selects a specific timezone, `tzinfo=None` falls back to the current
  timezone, and `USE_TZ=False` disables conversion.
- E9: `TruncDate` and `TruncTime` must remain cast-specific functions rather
  than routing through generic truncation SQL.
- E12: the backend APIs already accept `tzname`, so the source obligation is to
  pass the correct value.

## Formal model

The K model in `fvk/mini-django-trunc.k` abstracts:

- `self.tzinfo is None` as `noTzInfo()`;
- `timezone._get_timezone_name(self.tzinfo)` as `someTz(EXPLICIT_NAME)`;
- `timezone.get_current_timezone_name()` as symbolic `CURRENT`;
- `compiler.compile(self.lhs)` as symbolic `(LHS, PARAMS)`;
- backend rendering as `castDate(LHS, TZARG)` or `castTime(LHS, TZARG)`.

This is intentionally property-complete for the reported defect: it preserves
the axis that can distinguish pass from fail, namely whether the backend cast
receives the explicit timezone, the current timezone, or no timezone.

## Function contracts

`getTzName(USE_TZ, TZINFO, CURRENT)`:

- returns `noSqlTz()` when `USE_TZ` is false;
- returns `sqlTz(CURRENT)` when `USE_TZ` is true and `TZINFO` is absent;
- returns `sqlTz(EXPLICIT)` when `USE_TZ` is true and `TZINFO` is present.

`truncDateAsSql(USE_TZ, TZINFO, CURRENT, LHS, PARAMS)`:

- returns `sqlResult(castDate(LHS, selected_timezone), PARAMS)`;
- the selected timezone is exactly the `getTzName()` result for the same
  `USE_TZ`, `TZINFO`, and `CURRENT` inputs.

`truncTimeAsSql(USE_TZ, TZINFO, CURRENT, LHS, PARAMS)`:

- returns `sqlResult(castTime(LHS, selected_timezone), PARAMS)`;
- the selected timezone is exactly the `getTzName()` result for the same
  `USE_TZ`, `TZINFO`, and `CURRENT` inputs.

No loops or recursive functions are present in the audited slice, so no
circularity claims are required.

## Adequacy

`fvk/FORMAL_SPEC_ENGLISH.md` paraphrases every K claim. `fvk/SPEC_AUDIT.md`
marks each paraphrase as passing against `fvk/INTENT_SPEC.md`. No claim is
legacy-derived or under-specified.


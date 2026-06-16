# FVK Specification for django__django-16429

Status: constructed, not machine-checked. No tests, Python, `kompile`, or
`kprove` were run.

## Intent Spec

`timesince(d, now=None, reversed=False, time_strings=None, depth=2)` should
return a human-readable elapsed time for datetime/date inputs. For the reported
regression, when `d` is an aware datetime at least one month in the past and
`now` is omitted under timezone-aware operation, `timesince(d)` must not raise
`TypeError`; it should return the same month-based string that the existing
calendar algorithm computes for naive inputs, including the reported
`"1 month"` example.

The intended domain for this audit is the normal `timesince()` domain after
date-to-datetime conversion where the initial `delta = now - d` subtraction is
defined. Explicit naive/aware mismatches are outside this proof slice because
the function already raises before the month/year pivot is constructed, and the
template filters intentionally catch `TypeError` for that case.

## Public Evidence Ledger

| ID | Source | Evidence | Obligation | Status |
| --- | --- | --- | --- | --- |
| E1 | problem | "`timesince()` raises `TypeError` with `USE_TZ=True` and `>1 month` interval" | Month/year intervals with aware datetimes must not create a naive/aware subtraction mismatch. | Encoded by PO-003 and K claim `remainingV1`. |
| E2 | problem | "`timezone.now() - datetime.timedelta(days=31)`" and expected `"1 month"` | The default `now` path for aware `d` is in scope. | Encoded by PO-007. |
| E3 | problem hint | "pivot ... does not take into account the datetime object's `tzinfo`" | The constructed pivot must preserve the input datetime's timezone information. | Encoded by K claim `pivotV1`. |
| E4 | source docstring | "The algorithm takes into account the varying duration of years and months." | Keep the existing calendar month/year calculation; do not replace it with fixed-day arithmetic or UTC normalization. | Encoded by PO-006 frame condition. |
| E5 | source docstring | "Seconds and microseconds are ignored." | The pivot constructor's existing zero-microsecond behavior is preserved. | Encoded by PO-006 frame condition. |
| E6 | public tests | Date objects, naive datetimes, differing timezones, depth, and month-edge outputs are covered in existing public tests. | Do not change signatures, date conversion, formatting, depth, or month-edge calculations. | Encoded by PO-004, PO-006, and compatibility audit. |
| E7 | public tests | Template filters expect `""` when explicit naive/aware mismatches raise `TypeError`. | Do not attempt to hide every `TypeError` inside `timesince()` itself. | Encoded by PO-002. |

## Formal Model

The FVK mini semantics intentionally models only the property axis that produced
the bug: whether datetimes are in the same Python subtraction-awareness class.
It abstracts actual offsets, localized calendar arithmetic, translation, and
string joining, because the V1 diff does not change those code paths. The model
keeps the relevant discriminator:

- A failing pre-fix pivot maps an aware input to a `Naive` pivot.
- The V1 pivot maps an aware input to an `Aware` pivot and a naive input to a
  `Naive` pivot.
- Python datetime subtraction is modeled as defined for `Aware/Aware` and
  `Naive/Naive`, and as `typeError` for mixed classes.

The K files are:

- `fvk/mini-timesince.k`: mini semantics for pivot construction and subtraction
  definedness.
- `fvk/timesince-spec.k`: K reachability claims for timezone preservation and
  remaining-time subtraction definedness.

Exact commands to machine-check later, not executed here:

```sh
kompile fvk/mini-timesince.k --backend haskell
kast --backend haskell fvk/timesince-spec.k
kprove fvk/timesince-spec.k
```

## Formal Spec English

Claim `pivotV1`: for any valid month/day parameters in the month/year branch,
constructing the V1 pivot preserves the start datetime's hour, minute, second,
clamped day, and timezone-awareness class.

Claim `remainingV1`: for any `now` and `d` whose subtraction-awareness class is
the same before the pivot is made, the V1 month/year pivot also has that same
class, so `now - pivot` is defined rather than raising the reported
offset-naive/offset-aware `TypeError`.

## Spec Audit

The formal claims pass the adequacy gate for the reported regression. They are
not candidate-derived restatements of the new code alone: E1-E3 independently
identify the pivot's missing timezone information as the defect, while E4-E7
bound the frame conditions around the rest of the function.

The formal model is intentionally partial. It does not machine-prove all
localized calendar offsets, translations, or the full string assembly algorithm.
Those are treated as frame obligations because the source edit only supplies
`tzinfo=d.tzinfo` to the existing pivot constructor.

## Public Compatibility Audit

Changed public symbol: `django.utils.timesince.timesince()`.

Compatibility result: pass. V1 does not change the function signature, return
type, template filter signatures, `timeuntil()` wrapper signature, or humanize
call shape. Public callers under `django/template/defaultfilters.py` and
`django/contrib/humanize/templatetags/humanize.py` continue to call the same
APIs. No public override or virtual dispatch compatibility issue is present.

# django__django-14170 — FVK analysis

- **Verdict:** C_ROBUSTNESS — fvk adds a `value == datetime.MAXYEAR` guard that prevents a real `ValueError: Year is out of range: 10000` crash on `filter(field__iso_year=9999)`, a crash that **both baseline AND the human gold fix** hit.
- **Pitch-worthiness (1-5):** 4

## The issue
`__iso_year` lookups compute BETWEEN bounds for an ISO year. The ISO-year upper bound is derived as `fromisocalendar(value + 1, 1, 1) - 1unit`.

## What baseline did
Baseline (and gold) compute the upper bound by calling `datetime.date.fromisocalendar(value + 1, 1, 1)`. For `value == 9999` (`datetime.MAXYEAR`) this evaluates `fromisocalendar(10000, ...)`, which raises `ValueError: Year is out of range: 10000`.

## What fvk changed and why
fvk refactored the bound helpers and added an explicit guard:
```python
if value == datetime.MAXYEAR:
    second = datetime.date.max        # / datetime.datetime.max
```
so the MAXYEAR upper bound is `9999-12-31` instead of overflowing. (The surrounding helper-method refactor vs gold's `iso_year=` keyword is stylistic/equivalent — only the MAXYEAR guard is substantive.)

## Concrete demonstration
```python
Model.objects.filter(start_date__iso_year=9999)
```
| variant | result |
|---|---|
| **baseline** | `ValueError: Year is out of range: 10000` |
| **gold (oracle)** | `ValueError: Year is out of range: 10000` (same crash) |
| **fvk** | returns bounds `[9999-01-04, 9999-12-31]` ✅ |

`9999-12-31` is genuinely ISO year 9999 (week 52), and calendar `__year=9999` works fine, so `__iso_year=9999` is a legitimate, reachable query.

## Why the tests missed it
The FAIL_TO_PASS test (`test_extract_iso_year_func_boundaries`) only checks ISO years 2014/2015 — it never exercises year 9999. So both baseline and gold pass despite the latent crash; the MAXYEAR boundary is an untested edge.

## Gold comparison
Gold unconditionally computes `fromisocalendar(value + 1, 1, 1)` with no MAXYEAR special case — so gold crashes too. **GOLD_MATCH: no** — this is a case where fvk is *more correct than the human fix*.

## Confidence & caveats
- **Med-high confidence:** the crash was confirmed by directly executing the exact bound expressions for `value=9999`; a full DB queryset wasn't stood up (the lookup path unconditionally calls these helpers, so the crash is reached).
- It's a MAXYEAR-only edge case (rare in practice), but a genuine uncaught crash that the official fix shares.

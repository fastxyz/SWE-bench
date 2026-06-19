# All 21 verified instances at a glance

Every instance below is one where **baseline passed all tests AND FVK passed all tests, but FVK changed the code.** Each was analyzed by executing the baseline / FVK / official-human-fix versions. Click an instance for the full write-up and the concrete distinguishing input.

**Categories:** `A` real bug fix · `B` completeness (fixed the same bug in places baseline left) · `C` robustness (hardening on untested inputs) · `D` equivalent (same behavior, different code) · `E` cosmetic.

**Pitch:** 1–5 how compelling as a "passed tests but still wrong" story. **Better than human:** is FVK more correct than the merged upstream fix?

| Instance | Cat | Pitch | Better than human? | One line |
|---|:--:|:--:|:--:|---|
| [pydata__xarray-4094](pydata__xarray-4094/ANALYSIS.md) | A | 5 | ✅ | Stack→unstack round-trip silently destroys single-row dimensions — in baseline *and* the official fix; FVK preserves them |
| [django__django-11206](django__django-11206/ANALYSIS.md) | A | 4 | matches | A plain zero prints as garbage `0.00e+200`; FVK renders `0.00` |
| [matplotlib__matplotlib-25960](matplotlib__matplotlib-25960/ANALYSIS.md) | A | 4 | partial | User GridSpec subplot-spacing leaks into `add_subfigure()` placement; FVK scopes it like the official fix |
| [django__django-13569](django__django-13569/ANALYSIS.md) | A | 4 | matches orig | Baseline drops a correlated subquery from GROUP BY → wrong rows / Postgres error; FVK keeps it |
| [django__django-14725](django__django-14725/ANALYSIS.md) | A | 3 | matches | "Edit-only" formset can still silently create forbidden records (bypassable guard); FVK closes it |
| [sphinx-doc__sphinx-9367](sphinx-doc__sphinx-9367/ANALYSIS.md) | B | 5 | ✅ | One-element tuple subscript `obj[1,]`→`obj[1]` (wrong) — missed by AI, tests, *and* human maintainers; FVK fixes it |
| [django__django-13121](django__django-13121/ANALYSIS.md) | B | 4 | ✅ | A duration query crashes baseline *and* the official fix (TypeError on SQLite/MySQL); FVK returns the right value |
| [astropy__astropy-14096](astropy__astropy-14096/ANALYSIS.md) | B | 4 | ✅ | Subclass-property error is misleading because baseline truncates the inheritance scan; FVK reports the real cause |
| [sympy__sympy-14531](sympy__sympy-14531/ANALYSIS.md) | B | 4 | ✅ (Interval) | Baseline fixed 2 of 9 printers; FVK fixed the other 7 with the identical latent bug |
| [scikit-learn__scikit-learn-11310](scikit-learn__scikit-learn-11310/ANALYSIS.md) | B | 2 | partial | FVK also adds the feature to a deprecated duplicate module (low value; the official fix skipped it) |
| [scikit-learn__scikit-learn-13496](scikit-learn__scikit-learn-13496/ANALYSIS.md) | C | 4 | matches | New param inserted mid-constructor silently shifts every positional caller's args; FVK appends it like the official fix |
| [django__django-14170](django__django-14170/ANALYSIS.md) | C | 4 | ✅ | `filter(field__iso_year=9999)` crashes baseline *and* the official fix; FVK guards the year boundary |
| [sympy__sympy-24066](sympy__sympy-24066/ANALYSIS.md) | C | 4 | ✅ | Baseline turned a clean `ValueError` into a confusing low-level `TypeError`; FVK restores the right error |
| [psf__requests-2931](psf__requests-2931/ANALYSIS.md) | C | 3 | matches | Baseline band-aided one caller; FVK fixed the shared root-cause encoder like the official fix |
| [sphinx-doc__sphinx-7910](sphinx-doc__sphinx-7910/ANALYSIS.md) | C | 2 | no | Extra defensive owner-resolution paths for niche/contrived cases |
| [django__django-14434](django__django-14434/ANALYSIS.md) | D | 1 | yes | Both versions correct & identical behavior; FVK just rephrased to match the human fix |
| [django__django-16454](django__django-16454/ANALYSIS.md) | D | 2 | partial | Baseline correct on all reachable inputs; FVK only aligns two unreachable edge cases to the human fix |
| [django__django-11532](django__django-11532/ANALYSIS.md) | D | 1 | partial | Baseline already fixed it like the human fix; FVK's extra line is harmless but redundant |
| [django__django-15732](django__django-15732/ANALYSIS.md) | E | 1 | partial | Behavior-preserving refactor; identical SQL on every backend |
| [matplotlib__matplotlib-23314](matplotlib__matplotlib-23314/ANALYSIS.md) | E | 2 | no | Defensive `renderer is None` guard on an unreachable path the shipped fix omits |
| [sympy__sympy-12481](sympy__sympy-12481/ANALYSIS.md) | E | 1 | yes | Reordered one boolean + added a doctest; behavior identical |

## Tally

| Category | Count |
|---|:--:|
| A — real bug fix | 5 |
| B — completeness | 5 |
| C — robustness | 5 |
| D — equivalent | 3 |
| E — cosmetic | 3 |
| **Genuine improvement (A+B+C)** | **15 / 21 (71%)** |
| **More correct than the official human fix** | **≥ 5** |

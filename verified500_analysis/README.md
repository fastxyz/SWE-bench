# verified500_analysis

Evidence that **passing the tests is not the same as being correct** — and that the FVK pass improves code quality even on problems the baseline AI *already passed*.

## Start here
- 📄 **[REPORT.md](REPORT.md)** — the full write-up (TL;DR, the numbers, 3 flagship examples, methodology). **Read this first.**
- 📊 **[SUMMARY_TABLE.md](SUMMARY_TABLE.md)** — all 21 analyzed instances at a glance.

## The 3 flagship examples
1. [pydata__xarray-4094](pydata__xarray-4094/ANALYSIS.md) — silent data loss that the official human fix *also* has.
2. [scikit-learn__scikit-learn-13496](scikit-learn__scikit-learn-13496/ANALYSIS.md) — passed every test, but silently broke backward compatibility for all existing callers.
3. [sphinx-doc__sphinx-9367](sphinx-doc__sphinx-9367/ANALYSIS.md) — a bug the AI, the tests, *and* the human maintainers all missed.

## What's in each instance folder
- `ANALYSIS.md` — verdict, the concrete failing input, why the tests missed it, comparison to the real human fix.
- `_materials/` — `baseline.patch`, `fvk.patch`, **`gold.patch`** (the real upstream human fix), the issue text, and the exact tests the grader ran.

## How instances were selected
Across the SWE-bench Verified runs (`verified001`–`verified050`), we kept every instance where **baseline passed AND FVK passed** the official tests, then the subset where the two solutions **differ** (FVK changed the code): **86 of 411**. We verified a 21-case sample by executing the code. See [REPORT.md](REPORT.md) for the honest numbers and caveats.

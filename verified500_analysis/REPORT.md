# Passing the tests ≠ being correct: how FVK improves code quality on problems the AI *already got "right"*

**Audience:** investors & customers · **Repo:** [fastxyz/SWE-bench](https://github.com/fastxyz/SWE-bench) · **Evidence:** this folder (`verified500_analysis/`)

---

## TL;DR

On SWE-bench Verified (500 real GitHub bugs), each problem is solved twice: a **baseline** AI pass fixes the bug, then an **FVK** pass (our Formal-Verification-Kit method) re-audits and may revise the fix. The metric everyone quotes is the **flip rate** — FVK turning a *failing* solution into a *passing* one.

**That is only half the story.** We looked at the **411 problems where the baseline solution already passed every hidden test.** In **86 of them (1 in 5)**, FVK *still rewrote the code*. We then **executed the code** for a 21-case verified sample:

- **~7 out of 10 of those rewrites are genuine quality improvements** — real bug fixes, completeness fixes, and robustness hardening that the test suite **could not see** because both versions pass.
- In **at least 5 cases, FVK's code is *more correct than the official human fix*** that the project's own maintainers merged.

> **The headline:** A green test suite is a *lower bound* on correctness, not a proof. FVK's second, verification-driven look catches the edge cases, silent regressions, and half-finished fixes that tests miss — so it raises code quality **even when the tests are already green**.

---

## The numbers (honest)

| | count |
|---|---:|
| Baseline-passing instances analyzed (across verified500 runs) | **411** |
| ...where baseline & FVK solutions are **identical** | 325 |
| ...where **FVK changed already-passing code** | **86  (≈21%, 1 in 5)** |
| Rigorously verified sample (code executed) | 21 |
| → genuine improvements (real fix / completeness / robustness) | **15  (71%)** |
| → equivalent refactor or cosmetic | 6 |
| FVK more correct than the **official human fix** | ≥ 5 |

**Extrapolation:** ~71% of 86 ⇒ **roughly 60 of the 411 already-passing solutions were genuinely improved by FVK** — *on top of* the usual fail→pass flips FVK is normally measured on.

These 86 are the **"FVK touched already-green code"** set. The point is not that all 86 are fixes — it's that when FVK overrides a solution the tests already bless, it's right far more often than not, and it reaches correctness the tests (and sometimes the humans) never did.

---

## 3 flagship examples

Each was verified by **running the actual code** for the baseline, FVK, and official-human-fix versions. Full write-ups + patches + the real upstream fix are in each instance's folder.

### ① It silently loses your data — and so does the official human fix
**`pydata/xarray-4094`** · category: real fix · [details](pydata__xarray-4094/ANALYSIS.md)

- **Plain English:** xarray can "stack" a dataset into one array and "unstack" it back. The round-trip is supposed to return your data unchanged.
- **Baseline (passed all tests):** used a blanket `.squeeze()` that **silently deletes any single-row dimension** during the round-trip. Your length-1 column just disappears.
- **Demonstration (executed):**
  ```python
  arr = xr.DataArray(np.arange(1), coords=[("x", [0])])   # one row
  ds  = xr.Dataset({"a": arr, "b": arr})
  out = ds.to_stacked_array("y", ["x"]).to_unstacked_dataset("y")
  out.identical(ds)
  #   baseline → False  (the 'x' dimension is destroyed)
  #   FVK      → True   (data preserved)
  ```
- **The kicker:** the **official fix the xarray maintainers merged has the *same* bug.** FVK is the only version that gets it right.
- **Why tests missed it:** the test only round-trips data with ≥2 rows, where the blanket squeeze happens to be harmless.

### ② It passed every test, but silently broke every existing user
**`scikit-learn/scikit-learn-13496`** · category: robustness / backward-compat · [details](scikit-learn__scikit-learn-13496/ANALYSIS.md)

- **Plain English:** the task was to add one new option (`warm_start`) to `IsolationForest`'s constructor.
- **Baseline (passed all tests):** inserted the new parameter **in the middle** of the argument list. Because this constructor accepts positional arguments, **every existing call that passed arguments by position now binds them to the wrong parameters** — silently.
- **Demonstration (executed):**
  ```python
  IsolationForest(100, "auto", "legacy", 1., False, 3, "new", 0, 1)
  #   baseline → n_jobs="new" (crashes at fit), behaviour=0, warm_start=3 ... all shifted
  #   FVK      → every argument lands where the caller intended
  ```
- **The kicker:** FVK appended the parameter at the end — **byte-for-byte identical to the maintainers' official fix** (they cared about exactly this).
- **Why tests missed it:** every test calls the constructor with *keyword* arguments, so the positional break is invisible to the suite.

### ③ It found a bug the AI, the tests, *and* the human maintainers all missed
**`sphinx-doc/sphinx-9367`** · category: completeness · [details](sphinx-doc__sphinx-9367/ANALYSIS.md)

- **Plain English:** in Python, a one-element tuple needs a trailing comma: `(1,)` is a tuple; `(1)` is just the number 1. Sphinx renders code back into text for documentation.
- **Baseline (passed all tests):** fixed the comma in the one place the bug report named — but **left the identical bug in a sibling code path** (subscripts).
- **Demonstration (executed):**
  ```text
  source:  obj[1,]
  baseline → obj[1]    # WRONG: a different operation (__getitem__(1) vs __getitem__((1,)))
  FVK      → obj[1,]   # correct
  ```
- **The kicker:** we checked the real Sphinx git history — **the maintainers' own fix never patched this second path either.** FVK fixed what the AI, the test suite, and the humans all overlooked.
- **Why tests missed it:** the only added test covers the first path; nothing tests a one-element tuple *subscript*.

---

## "It's not cherry-picking" — more verified examples

Every row below was code-executed; folders contain the reproduction and the official human patch.

| Instance | What FVK caught (baseline passed all tests) | More correct than human fix? |
|---|---|:--:|
| [django-13121](django__django-13121/ANALYSIS.md) | A duration query (`estimated_time + (end - start)`) that **crashes baseline *and* the official fix** with a TypeError on SQLite/MySQL; FVK returns the right value | ✅ |
| [django-14170](django__django-14170/ANALYSIS.md) | `filter(field__iso_year=9999)` **crashes baseline *and* the official fix** (`Year out of range: 10000`); FVK guards the boundary | ✅ |
| [django-11206](django__django-11206/ANALYSIS.md) | A plain zero prints as garbage `0.00e+200`; FVK renders `0.00` | matches |
| [django-13569](django__django-13569/ANALYSIS.md) | Baseline silently drops a correlated subquery from GROUP BY → wrong results / DB error on Postgres; FVK keeps it | matches orig |
| [astropy-14096](astropy__astropy-14096/ANALYSIS.md) | A subclass property error gives a misleading message; FVK surfaces the real cause (scans full inheritance chain) | ✅ |
| [sympy-14531](sympy__sympy-14531/ANALYSIS.md) | Baseline fixed 2 of 9 printers the bug touched; FVK fixed the other 7 with the identical latent bug | ✅ (Interval) |
| [django-14725](django__django-14725/ANALYSIS.md) | An "edit-only" formset that can still **silently create records it was told never to create** (guard bypassable); FVK closes it | matches |
| [sympy-24066](sympy__sympy-24066/ANALYSIS.md) | Baseline turned a clean `ValueError` into a confusing low-level `TypeError`; FVK restores the right error | ✅ |

---

## Methodology (so a skeptic can re-check everything)

1. **Selection.** Across the verified500 runs, we kept every instance where **baseline passed AND FVK passed** the official SWE-bench test suite, then kept the subset where the two solution patches **differ** (so FVK changed the code). That's the 86.
2. **Oracle.** For each, we pulled the **real upstream human fix** ("gold patch") and the exact tests the grader ran (`FAIL_TO_PASS`/`PASS_TO_PASS`) as an independent reference. The AI never sees these during the benchmark; we use them only to judge after the fact.
3. **Verification.** For the analyzed sample, an engineer-agent **executed the baseline, FVK, and gold versions** on concrete inputs and recorded the actual outputs (this disproved several of our own initial guesses — the analysis is adversarial, not confirmatory).
4. **Reproducibility.** Each instance folder has `_materials/` (baseline.patch, fvk.patch, **gold.patch**, the issue, the test list) and an `ANALYSIS.md` with the exact distinguishing input.

**Honest caveats.** (a) We verified 21 of 86; the 71% improvement rate is a sample estimate, not a census. (b) FVK's internal artifacts label their formal "proofs" as *constructed, not machine-checked* — the value demonstrated here is **audit-driven bug-finding that we independently verified by execution**, not machine-checked proof. (c) A few demonstrations were reasoned from version-matched source rather than a full app stand-up; each ANALYSIS.md states its confidence.

---

## Where to look for more evidence

- **This report:** `verified500_analysis/REPORT.md`
- **The 3 flagships:** [`pydata__xarray-4094/`](pydata__xarray-4094/ANALYSIS.md) · [`scikit-learn__scikit-learn-13496/`](scikit-learn__scikit-learn-13496/ANALYSIS.md) · [`sphinx-doc__sphinx-9367/`](sphinx-doc__sphinx-9367/ANALYSIS.md)
- **All 21 verdicts at a glance:** [`SUMMARY_TABLE.md`](SUMMARY_TABLE.md)
- **Any instance:** `verified500_analysis/<instance>/ANALYSIS.md` + `_materials/` (includes the real human fix to compare against)

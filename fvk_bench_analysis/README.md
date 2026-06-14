# FVK Bench — Post-Run Failure Analysis

Post-mortem of the instances where the **fvk arm failed** in batch1–5, asking one question per instance: **is the true root cause present (probably hidden) in the FVK-generated artifacts, or missing?** — and aggregating into FVK's **improvement headroom**.

- The plan: [PLAN.md](PLAN.md)
- The FVK decoder ring: [_shared/fvk-primer.md](_shared/fvk-primer.md)
- Cross-instance result: [SYNTHESIS.md](SYNTHESIS.md)
- Incidents / traceability log: [INCIDENTS.md](INCIDENTS.md)

## Macro context

Across batch1–5, **fvk and baseline verdicts are identical (zero flips)** — FVK never converted a baseline failure into a pass. This study asks whether the information needed to do so was nonetheless already present in FVK's output. The 11 failures span **6 repos** (astropy, django ×4, pytest, sphinx, xarray, sympy ×3).

## Per-instance verdicts

Verdict legend: **STATED** (named, not acted on / argued against) · **BURIED** (present in formal form, not surfaced) · **MISSING** (no trace, or inverted/certified-as-spec; note if unreachable from public data). STATED/BURIED count toward headroom.

| # | instance | batch | verdict | counts toward headroom? | analysis |
|---|----------|-------|---------|--------------------------|----------|
| 1 | astropy__astropy-13398   | batch1 | **MISSING** (reachable) | No | [link](astropy__astropy-13398/ANALYSIS.md) |
| 2 | django__django-10554     | batch1 | **MISSING** (reachable) | No | [link](django__django-10554/ANALYSIS.md) |
| 3 | django__django-12325     | batch1 | **STATED** | **Yes** | [link](django__django-12325/ANALYSIS.md) |
| 4 | django__django-13212     | batch1 | **MISSING** (reachable) | No | [link](django__django-13212/ANALYSIS.md) |
| 5 | django__django-16263     | batch3 | **MISSING** (reachable) | No | [link](django__django-16263/ANALYSIS.md) |
| 6 | pytest-dev__pytest-10356 | batch4 | **STATED** | **Yes** | [link](pytest-dev__pytest-10356/ANALYSIS.md) |
| 7 | sphinx-doc__sphinx-9229  | batch4 | **MISSING** (reachable) | No | [link](sphinx-doc__sphinx-9229/ANALYSIS.md) |
| 8 | pydata__xarray-6992      | batch5 | **MISSING** (reachable) | No | [link](pydata__xarray-6992/ANALYSIS.md) |
| 9 | sympy__sympy-13852       | batch5 | **STATED** | **Yes** | [link](sympy__sympy-13852/ANALYSIS.md) |
| 10 | sympy__sympy-16597      | batch5 | **STATED** | **Yes** | [link](sympy__sympy-16597/ANALYSIS.md) |
| 11 | sympy__sympy-18199      | batch5 | **MISSING** (reachable) | No | [link](sympy__sympy-18199/ANALYSIS.md) |

**Headroom: 4 / 11 root cause present in artifacts (all 11 analyzed).** See [SYNTHESIS.md](SYNTHESIS.md). All 4 present cases are STATED (fvk localized the fix, then formally argued itself out of it via a self-imposed constraint); all 7 MISSING are **reachable from public data** and none is a formal-expressiveness blind spot — the bottleneck is intent-fidelity/localization, not FVK's formal power.

- astropy-13398 → MISSING but **reachable**: fvk confirmed an incomplete V1 and declared the spec "clean and total on its domain," scoping the defect (`ITRS.location`, refraction, CIRS bridges) out.
- django-10554 → MISSING but **reachable**: fvk formalized an *unrelated* `Query.clone()` aliasing contract; the real cause (missing case in `get_order_by`) is absent.
- django-12325 → **STATED (counts)**: fvk quoted the oracle's one-line fix verbatim, then rejected it on the authority of a pre-fix in-repo test the gold patch deletes.
- django-13212 → MISSING but **reachable**: fvk scope-fenced to `core/validators.py` and never opened `forms/fields.py`, where the graded failure lives.
- django-16263 → MISSING but **reachable**: fvk *certified* V1's buggy single-SELECT output as correct; the mini-ORM abstracted away the SQL-shape axis the tests measure.
- pytest-10356 → **STATED (counts)**: the whole bug is `reversed(__mro__)`; fvk manufactured a flawed "forcing" proof obligation arguing the buggy order was required.
- sphinx-9229 → MISSING but **reachable** (half-fix): oracle needs `get_doc` + suppressing the `alias of` line in `add_content`; fvk did only `get_doc` and certified the rest as intended.
- xarray-6992 → MISSING but **reachable** (half-captured): coupled two-part bug; fvk captured the `coord_names` half but the graded loop half is abstracted into opaque `.k` sets and "proved byte-for-byte unchanged."
- sympy-13852 → **STATED (counts)**: fvk localized the `polylog.eval` placement + golden-ratio coverage, then rejected both (pre-fix display read as "stay unevaluated"; coverage as "enhancement").
- sympy-16597 → **STATED (counts)**: fvk named the gold fix `irrational == real & finite & !rational` verbatim, then rejected it as "exceeds issue/hint scope."
- sympy-18199 → MISSING but **reachable** (half-captured): fvk got the co-shipped prime zero-root bug but certified the composite-modulus `NotImplementedError` as a "contract to preserve"; the graded composite fix is absent.

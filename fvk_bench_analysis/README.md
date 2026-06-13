# FVK Bench — Post-Run Failure Analysis

Post-mortem of the instances where the **fvk arm failed** in batch1–4, asking one question per instance: **is the true root cause present (probably hidden) in the FVK-generated artifacts, or missing?** — and aggregating into FVK's **improvement headroom**.

- The plan: [PLAN.md](PLAN.md)
- The FVK decoder ring: [_shared/fvk-primer.md](_shared/fvk-primer.md)
- Cross-instance result: [SYNTHESIS.md](SYNTHESIS.md)
- Incidents / traceability log: [INCIDENTS.md](INCIDENTS.md)

## Macro context

Across batch1–4, **fvk and baseline verdicts are identical (zero flips)** — FVK never converted a baseline failure into a pass. This study asks whether the information needed to do so was nonetheless already present in FVK's output.

## Per-instance verdicts

Verdict legend: **STATED** (named, not acted on) · **BURIED** (present in formal form, not surfaced) · **MISSING** (no trace; note if unreachable from public data). STATED/BURIED count toward headroom.

| # | instance | batch | verdict | counts toward headroom? | analysis |
|---|----------|-------|---------|--------------------------|----------|
| 1 | astropy__astropy-13398   | batch1 | **MISSING** (reachable) | No | [link](astropy__astropy-13398/ANALYSIS.md) |
| 2 | django__django-10554     | batch1 | **MISSING** (reachable) | No | [link](django__django-10554/ANALYSIS.md) |
| 3 | django__django-12325     | batch1 | **STATED** | **Yes** | [link](django__django-12325/ANALYSIS.md) |
| 4 | django__django-13212     | batch1 | **MISSING** (reachable) | No | [link](django__django-13212/ANALYSIS.md) |
| 5 | django__django-16263     | batch3 | **MISSING** (reachable) | No | [link](django__django-16263/ANALYSIS.md) |
| 6 | pytest-dev__pytest-10356 | batch4 | **STATED** | **Yes** | [link](pytest-dev__pytest-10356/ANALYSIS.md) |
| 7 | sphinx-doc__sphinx-9229  | batch4 | **MISSING** (reachable) | No | [link](sphinx-doc__sphinx-9229/ANALYSIS.md) |

**Headroom: 2 / 7 root cause present in artifacts (all 7 analyzed).** See [SYNTHESIS.md](SYNTHESIS.md). Both present cases are STATED (fvk localized the fix, then formally argued itself out of it); all 5 MISSING are **reachable from public data** and none are formal-expressiveness blind spots — the bottleneck is intent-fidelity/localization, not FVK's formal power.
- astropy-13398 → MISSING but **reachable** from public data (issue text + source the agent opened): not latent in artifacts, but a real FVK *process* gap (it confirmed an incomplete V1 and scoped the defect out).
- django-10554 → MISSING but **reachable**: fvk formalized an *unrelated* `Query.clone()` aliasing contract; the real cause (missing case in `get_order_by`) is absent. "Could not reproduce" hedge inverted into confirming V1.
- django-12325 → **STATED (counts)**: fvk localized to the exact buggy region and quoted the oracle's one-line fix verbatim, then rejected it on the authority of a pre-fix in-repo test that the gold patch deletes. The answer was in the artifacts.
- django-13212 → MISSING but **reachable**: fvk scope-fenced all edits to `core/validators.py` and never opened `forms/fields.py`, where the graded failure's cause (`DecimalField.validate` NaN short-circuit) lives. (Eval over-count caveat logged in INCIDENTS — verdict unaffected.)
- django-16263 → MISSING but **reachable**: fvk *certified* V1's buggy single-SELECT output as correct (POSITIVE finding) and the mini-ORM abstracted away the SQL-shape axis the tests measure. Formalized the implementation, not the intent.
- pytest-10356 → **STATED (counts)**: the whole bug is one token (`reversed(__mro__)` vs forward). fvk audited exactly the ordering question, then manufactured a flawed "forcing" proof obligation (PO3) arguing the buggy order was required and predicting the wrong test output. Had the answer; formally argued itself out of it.
- sphinx-9229 → MISSING but **reachable** (tell #9, half-fix): oracle needs two coordinated edits (`get_doc` + suppress the `alias of` line in `add_content`); V1 did only `get_doc` and the artifacts certify rendering `alias of` *alongside* the doc-comment as the intended spec (`SPEC.md:53-56` Intent I1). `add_content` never audited.

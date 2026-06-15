# FVK Findings

Status: constructed, not machine-checked. Findings are based on public intent, source inspection, and symbolic string reasoning. No tests or code were run.

## F-1: Missing separator before `CASE` in distinct aggregate SQL

Classification: resolved code bug.

Input: `Count(Case(...), distinct=True)` or equivalent aggregate SQL with `function="COUNT"`, `distinct=True`, and expression SQL beginning `CASE WHEN ...`.

Pre-V1 observed behavior: `COUNT(DISTINCTCASE WHEN ...)`.

Expected behavior: `COUNT(DISTINCT CASE WHEN ...)`.

Evidence: public issue text E-1 and E-2; proof obligations PO-1 and PO-2.

V1 status: resolved by changing the true distinct marker to `DISTINCT ` in `Aggregate.as_sql()`.

## F-2: Backend fallback path must also be covered

Classification: resolved coverage finding.

Input: an aggregate with `distinct=True` and `filter=...` on a backend without native aggregate `FILTER` support.

Potential bad behavior: the fallback path rewrites the filter as `Case(...)`; if the distinct marker lacks the separator, this path can produce `COUNT(DISTINCTCASE WHEN ...)`.

Expected behavior: `COUNT(DISTINCT CASE WHEN ...)`.

Evidence: public issue says "whatever the db backend" (E-3); source fallback path E-6; proof obligation PO-4.

V1 status: resolved because the fixed `extra_context['distinct']` value is computed before both supported-filter and fallback branches and is passed into the fallback `Func.as_sql()` call.

## F-3: Non-distinct aggregate rendering must not change

Classification: resolved compatibility finding.

Input: `Count(Case(...), distinct=False)`.

Expected behavior: the marker is empty and the SQL shape remains `COUNT(CASE WHEN ...)`.

Evidence: I-3; proof obligation PO-3.

V1 status: resolved because `extra_context['distinct']` remains `''` when `self.distinct` is false.

## F-4: Public API and subclass compatibility

Classification: resolved compatibility finding.

Input: subclasses and mixins that call `Aggregate.as_sql()` through `super()`, such as Postgres orderable aggregates and GIS aggregates.

Expected behavior: signatures, return shape, and constructor behavior remain unchanged.

Evidence: public compatibility audit; proof obligation PO-6.

V1 status: resolved because V1 changes only an internal SQL context string and leaves method signatures and return values unchanged.

## F-5: Proof is constructed only

Classification: residual verification risk.

Input: the emitted K files and claims.

Observed status: commands were not run because the task forbids running K tooling.

Expected next validation: run the emitted `kompile`, `kast`, and `kprove` commands in an environment where K is available; expected result is `#Top`.

Evidence: FVK methodology honesty gate; proof obligations PO-7 and PO-8.

V1 status: not a source-code blocker. It limits proof confidence but does not surface a source change beyond V1.

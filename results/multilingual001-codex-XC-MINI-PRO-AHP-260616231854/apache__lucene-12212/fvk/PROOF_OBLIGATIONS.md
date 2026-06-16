# FVK Proof Obligations

Status: constructed, not machine-checked.

## O1: Public-intent completeness

For every candidate document `d`, if `d` satisfies the base query and every drill-down dimension, then no scorer branch may skip `d` because a two-phase matcher was confirmed twice at the same approximation position.

Source evidence: E1, E2, E4.

Discharged by: O2, O3, and branch-local proofs in `PROOF.md`.

## O2: Initialization uses candidate movement only

`score` initialization must move the base scorer with `baseApproximation.nextDoc()`, not `baseIterator.nextDoc()`, so no base `matches()` call occurs before branch-specific checks.

Source evidence: E3, E4, E6.

Code witness: `DrillSidewaysScorer.java` initializes with `baseApproximation.nextDoc()`.

## O3: Base two-phase confirmation is at most once per base candidate

Between two movements of `baseApproximation`, the code may call `baseTwoPhase.matches()` at most once for the current doc.

Source evidence: E4, E6.

Branch cases:

- Query-first single dimension: one call before dimension checks, then `baseApproximation.nextDoc()`.
- Query-first multi dimension: one call after approximation alignment, then next or advance.
- Drill-down-advance: one call in the base fold only when `baseApproximation.docID() == ddDocID`.
- Union: one call in the base loop before scoring the candidate, followed by `baseApproximation.nextDoc()`.

## O4: Base approximation-only docs are rejected

Any branch that scores or counts a base document must prove:

```text
baseExact(d) = baseTwoPhase == null || baseTwoPhase.matches() == true
```

Source evidence: E5.

Code witness: `doDrillDownAdvanceScoring` and `doUnionScoring` now use `baseApproximation` plus `baseTwoPhase` rather than relying on full-iterator state established before branch entry.

## O5: Scoring follows confirmation

If `baseTwoPhase != null`, `baseScorer.score()` must only be called on a doc after `baseTwoPhase.matches()` returned true at that same approximation position.

Source evidence: E5 and `PhraseScorer.score()` reading matcher state after `matches()`.

Code witness:

- Query-first: collectors receive `ScoreCachingWrappingScorer.wrap(baseScorer)` after the base two-phase check.
- Drill-down-advance and union: `baseScorer.score()` is inside the same condition that checks `baseTwoPhase`.

## O6: Dimension two-phase candidates are confirmed before seeding or counting

For each drill-down dimension candidate `d`, if that dimension has `twoPhase != null`, `dim.twoPhase.matches()` must return true before the doc is treated as a dimension match.

Source evidence: E2, E5, E7.

Code witness: query-first and union already follow this form; V2 fixes the `dims[1]` condition in drill-down-advance scoring.

## O7: `acceptDocs == null` does not imply two-phase success

The live-doc predicate and two-phase predicate are independent. The intended condition is:

```text
(acceptDocs == null || acceptDocs.get(d)) && (twoPhase == null || twoPhase.matches())
```

not:

```text
acceptDocs == null || (acceptDocs.get(d) && ...)
```

Source evidence: E5 and E8.

Code witness: V2 parenthesizes `dims[1]` in `doDrillDownAdvanceScoring`.

## O8: Compatibility and branch-selection frame

The fix must not change public APIs, branch-selection heuristics, collector wiring, chunk size, or hit/near-miss counting rules except where required to enforce exact two-phase confirmation.

Source evidence: task scope and public compatibility audit.

Code witness: only internal conditions and iterator movement in `DrillSidewaysScorer` changed.

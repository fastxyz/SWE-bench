# FVK Spec: apache__lucene-12212

Status: constructed, not machine-checked. No tests, Python, K tooling, or project code were run.

## Scope

Target production file:

- `repo/lucene/facet/src/java/org/apache/lucene/facet/DrillSidewaysScorer.java`

The formalization focuses on the observable behavior relevant to the issue: how `DrillSidewaysScorer` advances base and drill-down approximations, when it calls `TwoPhaseIterator.matches()`, and when a candidate document is eligible for hit or sideways collection.

## Intent Spec

1. A `DrillSideways` search must not miss a document that satisfies the base query and all drill-down dimensions.
2. A scorer with a `TwoPhaseIterator` exposes an approximation first; the candidate is an actual match only after `matches()` returns true.
3. `matches()` may be called at most once for a given two-phase iterator position, before the iterator is advanced again.
4. A phrase-backed base query or drill-down component is an in-domain two-phase scorer; it must be handled without corrupting phrase matcher state.
5. A document may contribute as a real hit only when the base query and all drill-down dimensions match. It may contribute as a near miss only when the base query matches and exactly one drill-down dimension misses.
6. Live-doc filtering is a guard on collection, not a substitute for two-phase confirmation. When `acceptDocs` is null, the candidate still needs any applicable two-phase check.
7. No public API or signature change is intended; this is an internal scorer correction.

## Public Evidence Ledger

| ID | Source | Evidence | Obligation | Status |
| --- | --- | --- | --- | --- |
| E1 | `benchmark/PROBLEM.md` | "Searches made via DrillSideways may miss documents that should match the query." | Complete matching docs must be eligible for collection. | Encoded in O1, O4, O5. |
| E2 | `benchmark/PROBLEM.md` | "whenever at least one component of the DrillDownQuery involved was of type PhraseQuery" | Phrase/two-phase scorers are in-domain for base or dimension components. | Encoded in O2, O3, O6. |
| E3 | `benchmark/PROBLEM.md` | "`baseIterator.nextDoc()` will always call the more costly matcher and never the approximation." | Initial positioning must use approximation movement, not full matching movement. | Encoded in O2. |
| E4 | `benchmark/PROBLEM.md` | "a second call to `TwoPhaseMatcher::matches` will be made without the iterator has been re-positioned" | At most one `matches()` call per positioned candidate. | Encoded in O3. |
| E5 | `TwoPhaseIterator.java` | The approximation is a superset and `matches()` is needed to know whether the doc actually matches. | Approximation-only docs must not be accepted as matches. | Encoded in O4, O5, O6. |
| E6 | `TwoPhaseIterator.java` | `matches()` should be called "at most once." | The proof must reject duplicate confirmation. | Encoded in O3. |
| E7 | `DrillSidewaysQuery.java` | `DocsAndCost` is created from each drill-down scorer and stores `twoPhase` plus `approximation`. | Drill-down dimensions follow the same two-phase contract as base. | Encoded in O6. |
| E8 | `DrillSidewaysScorer.java` | `doDrillDownAdvanceScoring` can seed candidates from `dims[1]`. | Dimension 1 must check its two-phase matcher even when `acceptDocs` is null. | Finding F3; fixed in V2. |

## Formal Spec English

The K-style claims in `fvk/drill-sideways-scorer-spec.k` paraphrase to:

- C1: `score` initialization advances the base approximation to a candidate but does not confirm the base two-phase matcher.
- C2: A branch may confirm a base candidate only after the approximation is positioned at that candidate.
- C3: A second base confirmation at the same iterator position is invalid.
- C4: A two-phase drill-down dimension, including dimension 1 in drill-down-advance scoring, may contribute only after `matches()` confirms the candidate.
- C5: Base collection requires live-doc eligibility and exact base matching, where exact matching is either no two-phase iterator or a true two-phase confirmation.

## Spec Audit

| Claim | Adequacy result |
| --- | --- |
| C1 | Pass. It directly matches E3 and removes the premature full-iterator confirmation. |
| C2 | Pass. It matches E5 and the scorer's intended approximation/confirmation split. |
| C3 | Pass. It directly matches E4 and E6. |
| C4 | Pass. It follows from E2, E5, E7, and E8. This is the audit item that V1 did not fully satisfy. |
| C5 | Pass. It follows from E1, E5, and the scorer comments around hit/near-miss collection. |

No claim is derived solely from the V1 implementation. The only implementation-derived facts are control-flow shape and state names used to model the branch-specific proof.

## Public Compatibility Audit

No public class, method signature, constructor signature, return type, exception type, or collector protocol changed. The edits are internal to package-private `DrillSidewaysScorer` and preserve the existing branch-selection cost heuristic.

## K Artifacts

Formal core:

- `fvk/mini-java-drillsideways.k`
- `fvk/drill-sideways-scorer-spec.k`

Exact commands for later machine checking, not run here:

```sh
kompile fvk/mini-java-drillsideways.k --backend haskell
kast --backend haskell fvk/drill-sideways-scorer-spec.k
kprove fvk/drill-sideways-scorer-spec.k
```

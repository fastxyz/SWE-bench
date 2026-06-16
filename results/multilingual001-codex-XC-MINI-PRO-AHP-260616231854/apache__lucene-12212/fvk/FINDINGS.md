# FVK Findings

Status: constructed, not machine-checked. Findings are from public intent, source inspection, and proof-obligation construction only.

## F1: V1 correctly removed premature base two-phase confirmation

Evidence: `benchmark/PROBLEM.md` identifies `baseIterator.nextDoc()` during scorer positioning as the first `matches()` call, followed by another branch-local `matches()` call at the same iterator position.

Observed pre-fix behavior: for a phrase-backed base scorer, initial positioning could call phrase matching through the full iterator before the selected scorer branch performed its own base two-phase check.

Expected behavior: base initialization should advance to the first candidate only. Confirmation should happen once, inside the selected branch, after the branch knows the candidate is still relevant.

Status: fixed by V1 and retained. `score` now calls `baseApproximation.nextDoc()` during initialization.

Related obligations: O1, O2, O3.

## F2: V1 correctly made chunked base paths confirm approximation candidates

Evidence: `TwoPhaseIterator.asDocIdSetIterator` reports `docID()` from the approximation. After changing initialization to `baseApproximation.nextDoc()`, a chunked branch that continued to read from `baseIterator.docID()` could observe an unconfirmed approximation candidate.

Observed V1-audit risk if only the one-line issue hint were applied: `doUnionScoring` or `doDrillDownAdvanceScoring` could score/count a base approximation candidate without checking `baseTwoPhase.matches()`.

Expected behavior: every base document used for scoring or counting must be exact: either the base scorer has no two-phase iterator or `baseTwoPhase.matches()` has returned true for the current approximation position.

Status: fixed by V1 and retained. `doUnionScoring` and `doDrillDownAdvanceScoring` now advance `baseApproximation` and explicitly check `baseTwoPhase`.

Related obligations: O2, O4, O5.

## F3: V1 missed a dimension two-phase check in drill-down-advance scoring

Evidence: in `doDrillDownAdvanceScoring`, the V1 condition for `dims[1]` was:

```java
if (acceptDocs == null
    || acceptDocs.get(docID) && (dc.twoPhase == null || dc.twoPhase.matches())) {
```

Because `&&` binds tighter than `||`, `acceptDocs == null` made the whole condition true without evaluating `dc.twoPhase.matches()`.

Observed V1 behavior for a phrase-backed second drill-down dimension and no live-doc bitset: an approximation-only dimension candidate could seed the chunk as if the phrase matched.

Expected behavior: `acceptDocs == null` means there is no live-doc filter to reject the doc. It does not mean the two-phase dimension matched. The candidate must still satisfy `(dc.twoPhase == null || dc.twoPhase.matches())`.

Status: fixed in V2 by parenthesizing the live-doc guard:

```java
if ((acceptDocs == null || acceptDocs.get(docID))
    && (dc.twoPhase == null || dc.twoPhase.matches())) {
```

Related obligations: O6, O7.

## F4: Proof remains constructed, not machine-checked

Evidence: the task forbids running K tooling, tests, Python, or project code.

Observed limitation: the FVK model is an abstract state-machine fragment for iterator movement and two-phase confirmation. It is not a full Java or Lucene semantics.

Expected behavior: report the exact commands for later checking and keep test-removal recommendations conditional.

Status: residual proof capability limitation, not a source-code bug.

Related obligations: O8.

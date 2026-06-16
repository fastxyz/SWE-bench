# FVK Proof

Status: constructed, not machine-checked. No `kompile`, `kast`, `kprove`, tests, Python, or project code were run.

## Formal Core

The model files are:

- `fvk/mini-java-drillsideways.k`
- `fvk/drill-sideways-scorer-spec.k`

Exact commands for later machine checking:

```sh
kompile fvk/mini-java-drillsideways.k --backend haskell
kast --backend haskell fvk/drill-sideways-scorer-spec.k
kprove fvk/drill-sideways-scorer-spec.k
```

Expected machine-check outcome after the mini-semantics is accepted: `#Top` for the stated claims.

## Adequacy Gate

The English intent in `SPEC.md` requires two properties: no duplicate two-phase confirmation at one iterator position, and no approximation-only candidate accepted as an exact match. The K-style claims paraphrased in `SPEC.md` C1-C5 state exactly those properties. No claim preserves the legacy `baseIterator.nextDoc()` behavior or the V1 `acceptDocs == null || ...` dimension shortcut.

## Proof Sketch

### Initialization

V2 executes `baseApproximation.nextDoc()` during `score` setup. In the model this is `nextApprox(base, D)`, which changes the base position but leaves `<confirmed>` unchanged. Therefore no base `matches()` call has occurred before branch dispatch. This discharges O2 and the initialization part of O3.

### Query-first single dimension

Loop invariant at the head of each iteration:

```text
baseApproximation.docID() == docID
and baseTwoPhase has not been called for docID since the last base approximation movement.
```

If `acceptDocs` rejects `docID`, the branch advances the approximation and calls no matcher. If `baseTwoPhase != null`, the branch calls `baseTwoPhase.matches()` once. On false, it advances the approximation. On true, it checks the single dimension once if needed, then collects a hit or near miss. Each exit from the iteration advances `baseApproximation`, so the next iteration has a fresh position. O3, O4, and O5 hold.

### Query-first multiple dimensions

The multi-dimension path first aligns dimension approximations. If more than one dimension approximation misses, it advances the base approximation to a later candidate without calling `baseTwoPhase.matches()` for the skipped candidate. Once at most one dimension approximation has missed, it calls `baseTwoPhase.matches()` at most once for the current base candidate. Dimension two-phase matchers are then called only for dimensions positioned on the same candidate and only until the second dimension failure would reject the candidate. Collection happens only after the base confirmation succeeds. O3, O4, O5, and O6 hold.

### Drill-down-advance

The chunk seed from `dims[0]` records a doc only when the doc is live and the dimension is exact. V2 applies the same structure to `dims[1]`:

```java
if ((acceptDocs == null || acceptDocs.get(docID))
    && (dc.twoPhase == null || dc.twoPhase.matches())) {
```

This is the proof-critical change for F3: when `acceptDocs == null`, the live-doc guard is true but the dimension still must pass `dc.twoPhase.matches()` if it has a two-phase iterator. So `seen` contains only exact dimension candidates for dimensions 0 and 1.

The base fold then compares each seeded doc with `baseApproximation`. If the base approximation is behind, it advances to the seeded doc. If the approximation lands on the seeded doc, the code accepts it only when `baseTwoPhase == null || baseTwoPhase.matches()`. Otherwise it clears the slot. Since the loop visits each seeded doc once in increasing chunk-slot order, each base candidate receives at most one base `matches()` call before the next approximation advance. O3, O4, O5, O6, and O7 hold.

### Union

The union branch iterates `baseApproximation` directly. For each candidate, it collects/scales the base slot only under:

```java
(acceptDocs == null || acceptDocs.get(docID))
    && (baseTwoPhase == null || baseTwoPhase.matches())
```

The loop then advances `baseApproximation.nextDoc()`. Thus every scored base doc is live and exact, and each candidate receives at most one base two-phase confirmation. The subsequent dimension loops only increase counts when positioned dimensions are exact. O3, O4, O5, and O6 hold.

## Residual Risk

The proof is partial correctness over the modeled scorer state machine. It does not prove termination, performance, or full Java/Lucene semantics. It does not justify removing tests because the machine check was not run. The FVK findings are still actionable because they derive from public intent, Java operator precedence, and Lucene's public two-phase iterator contract.

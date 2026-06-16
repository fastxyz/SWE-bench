requires "mini-java-drillsideways.k"

module DRILL-SIDEWAYS-SCORER-SPEC
  imports MINI-JAVA-DRILLSIDEWAYS
  imports INT
  imports BOOL
  imports MAP
  imports LIST

  syntax Bool ::= eligible(Phase, Int) [function]
  rule eligible(P:Phase, D:Int) => live(D) andBool (notBool hasTwoPhase(P) orBool exact(P, D))
    [function]

  // SPEC-PROVENANCE:
  // - from_problem: "Searches made via DrillSideways may miss documents that should match" =>
  //   matching documents must not be lost by corrupting phrase two-phase matcher state.
  // - from_problem: "matches() ... at most once" =>
  //   a two-phase scorer may be confirmed at most once between approximation movements.
  // - from_code: DrillSidewaysScorer.score positions base and dimension approximations before
  //   dispatching to query-first, drill-down-advance, or union scoring.
  claim <k> nextApprox(base, D:Int) => .K ... </k>
        <pos> POS => POS [ base <- D ] </pos>
        <confirmed> C => C </confirmed>
        <accepted> A => A </accepted>
        <trace> T => T ListItem(nextApprox(base, D)) </trace>
    ensures notBool confirmed(C, base, D)
    [all-path]

  // SPEC-PROVENANCE:
  // - from_problem: the erroneous pre-fix path confirms base via baseIterator.nextDoc()
  //   and then confirms it again in the selected scorer.
  // - from_TwoPhaseIterator_docs: approximation returns a superset; matches confirms it.
  claim <k> nextApprox(base, D:Int) ~> confirm(base, D) => exact(base, D) ... </k>
        <pos> POS => POS [ base <- D ] </pos>
        <confirmed> C => C [ base <- D ] </confirmed>
        <accepted> A => A </accepted>
        <trace> T => T ListItem(nextApprox(base, D)) ListItem(confirm(base, D)) </trace>
    requires hasTwoPhase(base)
    [all-path]

  // SPEC-PROVENANCE:
  // - from_TwoPhaseIterator_docs: matches() must be called at most once per positioned doc.
  // - from_code: query-first, drill-down-advance, and union all consume base candidates.
  claim <k> confirm(base, D:Int) ~> confirm(base, D) => .K ... </k>
        <pos> ... base |-> D ... </pos>
        <confirmed> C </confirmed>
        <accepted> A </accepted>
        <trace> T </trace>
    requires hasTwoPhase(base) andBool confirmed(C, base, D)
    ensures false
    [all-path]

  // SPEC-PROVENANCE:
  // - from_problem: a DrillDownQuery component may be a PhraseQuery, hence a dimension
  //   candidate with a two-phase iterator must be confirmed before it contributes.
  // - from_code: doDrillDownAdvanceScoring seeds its chunk from dims[0] and dims[1].
  claim <k> confirm(dim(1), D:Int) ~> collectDim(1, D) => .K ... </k>
        <pos> ... dim(1) |-> D ... </pos>
        <confirmed> C => C [ dim(1) <- D ] </confirmed>
        <accepted> A => A [ dim(1) <- D ] </accepted>
        <trace> T => T ListItem(confirm(dim(1), D)) ListItem(collectDim(1, D)) </trace>
    requires live(D) andBool hasTwoPhase(dim(1)) andBool exact(dim(1), D)
    [all-path]

  // SPEC-PROVENANCE:
  // - from_problem: matching documents must be returned exactly when the base query and
  //   all drill-down dimensions match; near misses are allowed only for sideways counts.
  // - from_code: collectHit is reached after base plus all dimensions pass; collectNearMiss
  //   is reached after base plus all but one dimension pass.
  claim <k> collectBase(D:Int) => .K ... </k>
        <pos> ... base |-> D ... </pos>
        <confirmed> C </confirmed>
        <accepted> A => A [ base <- D ] </accepted>
        <trace> T => T ListItem(collectBase(D)) </trace>
    requires live(D) andBool (notBool hasTwoPhase(base) orBool confirmed(C, base, D))
    [all-path]
endmodule

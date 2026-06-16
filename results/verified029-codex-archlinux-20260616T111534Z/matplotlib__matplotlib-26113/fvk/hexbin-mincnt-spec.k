requires "mini-hexbin.k"

module HEXBIN-MINCNT-SPEC-SYNTAX
  imports MINI-HEXBIN-SYNTAX
endmodule

module HEXBIN-MINCNT-VERIFICATION
  imports HEXBIN-MINCNT-SPEC-SYNTAX
  imports MINI-HEXBIN
  imports INT
  imports BOOL
  imports LIST
  imports K-EQUAL

  syntax Bool ::= allNonNegative(List) [function]
  rule allNonNegative(.List) => true
  rule allNonNegative(ListItem(N:Int) REST:List)
    => (N >=Int 0) andBool allNonNegative(REST)

  syntax List ::= keepAtLeast(List, Int) [function]
  rule keepAtLeast(.List, TH:Int) => .List
  rule keepAtLeast(ListItem(N:Int) REST:List, TH:Int)
    => ListItem(N >=Int TH) keepAtLeast(REST, TH)
endmodule

module HEXBIN-MINCNT-SPEC
  imports HEXBIN-MINCNT-VERIFICATION

  // SPEC-PROVENANCE:
  // - from_prompt: "at least 1 datum" and "len(vals) >= mincnt" =>
  //   the selected predicate is inclusive.
  // - from_code: the source loops over finite bins and appends one output
  //   decision per bin.
  claim
    <k> loop(TH:Int, COUNTS:List, OUT:List)
      => OUT keepAtLeast(COUNTS, TH) ... </k>
    requires TH >=Int 0 andBool allNonNegative(COUNTS)
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: count-only mincnt=1 "plots only gridpoints that have at
  //   least 1 datum".
  claim
    <k> select(countMode, some(M:Int), COUNTS:List)
      => keepAtLeast(COUNTS, M) ... </k>
    requires M >=Int 1 andBool allNonNegative(COUNTS)
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: "with mincnt == 1 I'd expect the same gridpoints to be
  //   plotted, whether C is supplied or not"
  // - from_prompt: "len(vals) >= mincnt, rather than ... len(vals) > mincnt"
  claim
    <k> select(cMode, some(M:Int), COUNTS:List)
      => keepAtLeast(COUNTS, M) ... </k>
    requires M >=Int 1 andBool allNonNegative(COUNTS)
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: with C specified but no mincnt, defaulting to non-empty bins
  //   is understandable because reducers may not handle empty arrays.
  claim
    <k> select(cMode, none, COUNTS:List)
      => keepAtLeast(COUNTS, 1) ... </k>
    requires allNonNegative(COUNTS)
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: no C and no mincnt shows all gridpoints, even zero-count
  //   cells.
  claim
    <k> select(countMode, none, COUNTS:List)
      => keepAtLeast(COUNTS, 0) ... </k>
    requires allNonNegative(COUNTS)
    [all-path]
endmodule

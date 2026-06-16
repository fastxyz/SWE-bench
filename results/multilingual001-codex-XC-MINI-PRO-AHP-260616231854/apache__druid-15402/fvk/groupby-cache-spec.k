requires "mini-java-cache.k"

module GROUPBY-CACHE-SPEC-SYNTAX
  imports MINI-JAVA-CACHE-SYNTAX
endmodule

module GROUPBY-CACHE-VERIFICATION
  imports MINI-JAVA-CACHE
  imports INT
  imports BOOL
  imports LIST
  imports MAP
  imports MAP-SYMBOLIC
  imports K-EQUAL

  syntax Bool ::= restoredFrom(Map, Int, List, Int) [function]
  rule restoredFrom(ROW:Map, START:Int, .List, I:Int) => true
  rule restoredFrom(ROW:Map, START:Int, ListItem(V) REST, I:Int)
    => (ROW [ START +Int I ] ==K V) andBool restoredFrom(ROW, START, REST, I +Int 1)

  rule restoredFrom(ROW:Map [ START +Int I <- V ], START:Int, ListItem(V) REST, I:Int)
    => restoredFrom(ROW [ START +Int I <- V ], START, REST, I +Int 1)
    [simplification]
endmodule

module GROUPBY-CACHE-SPEC
  imports GROUPBY-CACHE-VERIFICATION

  // SPEC-PROVENANCE:
  // - from_prompt: groupBy result-level cache with multiple post-aggregation metrics must not move a later metric
  //   into an earlier metric slot or leave later slots null.
  // - from_code: V1 loop writes ROW[START + postPos] and increments postPos after each read.
  // - from_domain: VALUES is the valid post-aggregator suffix emitted for the same query shape.
  claim [RESTORE-POSTAGGS]:
    <k> restorePostAggs(P:Int, START:Int) => .K ... </k>
    <postPos> 0 => P </postPos>
    <results> VALUES:List => .List </results>
    <row> ROW:Map => RESTORED:Map </row>
    requires P >=Int 0
     andBool size(VALUES) ==Int P
    ensures restoredFrom(RESTORED, START, VALUES, 0) ==K true
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt/hint: all post-aggregators must not be restored into the same index.
  // - loop invariant: postPos equals the number of restored post-aggregator values.
  claim [RESTORE-POSTAGGS-LOOP]:
    <k> loopPostAggs(P:Int, START:Int) => .K ... </k>
    <postPos> I:Int => P </postPos>
    <results> SUFFIX:List => .List </results>
    <row> ROW:Map => RESTORED:Map </row>
    requires 0 <=Int I
     andBool I <=Int P
     andBool size(SUFFIX) ==Int P -Int I
    ensures restoredFrom(RESTORED, START, SUFFIX, I) ==K true
    [all-path]
endmodule

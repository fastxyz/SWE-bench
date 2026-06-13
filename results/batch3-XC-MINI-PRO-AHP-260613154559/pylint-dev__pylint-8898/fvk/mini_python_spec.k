// Reachability claims for pylint._check_regexp_csv  (constructed, not machine-checked)
// See fvk_materials/commands/{formalize,verify}.md and fvk/PROOF.md.
requires "mini_python.k"

module MINI-PYTHON-SPEC-SYNTAX
  imports MINI-PYTHON-SYNTAX
endmodule

module VERIFICATION
  imports MINI-PYTHON-SPEC-SYNTAX
  imports MINI-PYTHON
  imports MAP-SYMBOLIC
  imports LIST
  imports K-EQUAL

  // ---- spec-only abstraction functions (spec vocabulary, NOT language) -----

  // inBrace(P): the running open_curly boolean AFTER scanning char-list P.
  // {  -> true ;  } -> false IF currently true ; anything else -> unchanged.
  syntax Bool ::= inBrace(List) [function]
  rule inBrace(.List) => false
  rule inBrace(P:List ListItem(C:String)) =>
         #if C ==String "{"  #then true
         #else #if C ==String "}" #then #if inBrace(P) #then false #else false #fi
               #else inBrace(P) #fi #fi

  // isSep(P, C): is char C a separator comma given the brace state of prefix P?
  // (A comma never changes inBrace, so the pre/post-update state coincide.)
  syntax Bool ::= isSep(List, String) [function]
  rule isSep(P:List, C:String) => C ==String "," andBool notBool inBrace(P)

  // split(V): the INTENDED output list. Partition V at separator commas into
  // segments, strip each, drop empties. Defined via a left-scan accumulator.
  // segs(P) = the sentinel-segment list the code builds for prefix P (a List
  // whose items are each either `none` or a char-List).
  syntax List ::= segs(List)           [function]
  syntax List ::= segsAux(List, List)  [function]   // segsAux(donePrefix, rest)
  rule segs(V:List) => segsAux(.List, V)
  rule segsAux(_, .List) => ListItem(none)                 // base seed [None] handled in claim
  // (full left-scan recursion elided here; its algebra is the loop step, below)

  // decode/filter: map a sentinel-segment list to the final string list.
  syntax List ::= emit(List) [function]                    // V2 result loop
  rule emit(.List) => .List
  rule emit(ListItem(none) R:List) => emit(R)
  rule emit(ListItem(L:List) R:List) =>
         #if trimWS(joinChars(L)) ==String ""
            #then emit(R)
            #else ListItem(trimWS(joinChars(L))) emit(R) #fi

  // split(V) = emit(segs(V)) seeded with the leading [None] sentinel.
  syntax List ::= split(List) [function]
  rule split(V:List) => emit(segs(V))
endmodule

module MINI-PYTHON-SPEC
  imports VERIFICATION

  // (C-STR) FUNCTION CONTRACT, str branch.
  // Running the body on a symbolic char-list VALUE leaves <out> = split(VALUE).
  // Precondition: none beyond "value is a str" (modelled as a char-List).
  claim
    <k> regexps = (ListItem(none) .List)
        open_curly = false
        for char in VALUE:Val : ( BODY:Stmt )
        for regexp in regexps  : ( RESULTLOOP:Stmt )
     => .K ... </k>
    <store> ( .Map => ?_:Map ) </store>
    <out>   ( .List => split(VALUE) ) </out>
    [all-path]

  // (C-LIST) FUNCTION CONTRACT, list/tuple branch: pass-through, unchanged.
  // _check_regexp_csv(value) yields exactly the elements of value, in order.
  claim
    <k> for x in VALUE:Val : ( yield x ) => .K ... </k>
    <out> ( .List => VALUE ) </out>
    requires isList(VALUE)
    [all-path]

  // (LOOP) SCAN-LOOP CIRCULARITY (the heart of the proof).
  // Generalized over the partially-built segment list R, brace state B, and the
  // UNSCANNED suffix REST. Running the scan loop from this state leaves regexps
  // equal to the segments obtained by continuing the left-scan of REST starting
  // from (R, B). Side condition ties B to the already-scanned prefix.
  claim
    <k> for char in REST:Val : ( BODY:Stmt ) => .K ... </k>
    <store>
      regexps    |-> ( R:List => scanFrom(R, B:Bool, REST) )
      open_curly |-> ( B       => brace(B, REST) )
      ... </store>
    [all-path]
  // scanFrom / brace are the obvious left-folds of the loop body's case logic;
  // brace(B, .List)=B ; scanFrom(R,B,.List)=R ; one-step unfolds are VC-STEP.

endmodule

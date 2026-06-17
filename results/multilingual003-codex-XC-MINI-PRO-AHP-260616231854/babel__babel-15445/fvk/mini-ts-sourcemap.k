module MINI-TS-SOURCEMAP-SYNTAX
  imports STRING-SYNTAX
  imports LIST-SYNTAX
  imports MAP-SYNTAX

  syntax Source ::= String
  syntax Content ::= String | "nullContent"
  syntax MaybeContents ::= "noContent" | "someContent" "(" List ")"
  syntax Stmt ::= "copyInput" "(" List "," MaybeContents ")"

  syntax KResult ::= Source | Content | MaybeContents | List | Map
endmodule

module MINI-TS-SOURCEMAP
  imports MINI-TS-SOURCEMAP-SYNTAX
  imports STRING
  imports LIST
  imports MAP

  configuration
    <k> $PGM:Stmt </k>
    <contents> .Map </contents>

  syntax Map ::= copyPairs(Map, List, List) [function]
  rule copyPairs(M:Map, .List, CS:List) => M
  rule copyPairs(M:Map, ListItem(S:Source) SS:List, .List) => M
  rule copyPairs(M:Map, ListItem(S:Source) SS:List, ListItem(C:Content) CS:List)
    => copyPairs(M[S <- C], SS, CS)

  rule <k> copyInput(SOURCES:List, noContent) => .K ... </k>

  rule <k> copyInput(.List, someContent(CONTENTS:List)) => .K ... </k>

  rule <k> copyInput(ListItem(S:Source) SOURCES:List, someContent(.List)) => .K ... </k>

  rule
    <k> copyInput(ListItem(S:Source) SOURCES:List, someContent(ListItem(C:Content) CONTENTS:List))
      => copyInput(SOURCES, someContent(CONTENTS)) ... </k>
    <contents> M:Map => M[S <- C] </contents>
endmodule

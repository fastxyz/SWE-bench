module MINI-PYTEST-VISIT-SYNTAX
  imports INT-SYNTAX
  imports BOOL-SYNTAX
  imports STRING-SYNTAX
  imports LIST
  imports MAP

  syntax Path ::= String
  syntax Entry ::= entry(String, Path, String)
  syntax RecursePolicy ::= recursePolicy(String)

  syntax Cmd ::= visit(Path, RecursePolicy)
               | emitAll(List)
               | descendAll(List, RecursePolicy)
               | emit(Entry)

  syntax KResult ::= List
endmodule

module MINI-PYTEST-VISIT
  imports MINI-PYTEST-VISIT-SYNTAX
  imports BOOL
  imports LIST
  imports MAP
  imports K-EQUAL

  configuration
    <k> $PGM:Cmd </k>
    <fs> .Map </fs>
    <out> .List </out>

  syntax List ::= sortedChildren(Map, Path) [function]
  syntax Bool ::= isDirFollow(Map, Entry) [function]
  syntax Bool ::= recurseAllows(RecursePolicy, Entry) [function]
  syntax Path ::= entryPath(Entry) [function]

  rule entryPath(entry(_, P, _)) => P

  rule <k> visit(P, R) => emitAll(sortedChildren(FS, P)) ~> descendAll(sortedChildren(FS, P), R) ... </k>
       <fs> FS </fs>

  rule <k> emitAll(.List) => .K ... </k>
  rule <k> emitAll(ListItem(E) ES) => emit(E) ~> emitAll(ES) ... </k>

  rule <k> emit(E) => .K ... </k>
       <out> O => O ListItem(E) </out>

  rule <k> descendAll(.List, _) => .K ... </k>

  rule <k> descendAll(ListItem(E) ES, R) => visit(entryPath(E), R) ~> descendAll(ES, R) ... </k>
       <fs> FS </fs>
    requires isDirFollow(FS, E) andBool recurseAllows(R, E)

  rule <k> descendAll(ListItem(E) ES, R) => descendAll(ES, R) ... </k>
       <fs> FS </fs>
    requires notBool (isDirFollow(FS, E) andBool recurseAllows(R, E))
endmodule


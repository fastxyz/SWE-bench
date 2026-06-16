// Constructed, not machine-checked.
// Minimal K-style model for the Sphinx gettext location transformation.
// This is an abstract mini-Python fragment over finite lists, paths, and
// locations. Path normalization is modeled by uninterpreted functions with
// the equations needed by the proof obligations.

module MINI-PYTHON-LOCATION-CATALOG-SYNTAX
  imports INT
  imports STRING
  imports LIST
  imports SET
  imports BOOL

  syntax Path ::= path(String)
  syntax Uuid ::= uuid(String)
  syntax Loc ::= loc(Path, Int)
  syntax Entry ::= entry(Path, Int, Uuid)

  syntax Path ::= normCwd(Path) [function]
  syntax Path ::= renderOut(Path) [function]

  syntax List ::= normalizeEntries(List) [function]
                | stableUnique(List) [function]
                | uniqueSeen(List, Set) [function]
                | renderLocs(List) [function]

  syntax Bool ::= noDup(List) [function]
                | locIn(Loc, List) [function]
                | sameRendered(Loc, Loc) [function]
endmodule

module MINI-PYTHON-LOCATION-CATALOG
  imports MINI-PYTHON-LOCATION-CATALOG-SYNTAX

  configuration <k> $PGM:K </k>

  // Abstract path law matching Sphinx relpath composition:
  // rendering after cwd-normalization preserves the final rendered spelling.
  rule renderOut(normCwd(P:Path)) => renderOut(P)

  rule normalizeEntries(.List) => .List
  rule normalizeEntries(ListItem(entry(P:Path, L:Int, U:Uuid)) REST:List)
    => ListItem(loc(normCwd(P), L)) normalizeEntries(REST)

  rule stableUnique(LS:List) => uniqueSeen(LS, .Set)
  rule uniqueSeen(.List, SEEN:Set) => .List
  rule uniqueSeen(ListItem(LOC:Loc) REST:List, SEEN:Set)
    => uniqueSeen(REST, SEEN)
    requires LOC in SEEN
  rule uniqueSeen(ListItem(LOC:Loc) REST:List, SEEN:Set)
    => ListItem(LOC) uniqueSeen(REST, SetItem(LOC) SEEN)
    requires notBool (LOC in SEEN)

  rule renderLocs(.List) => .List
  rule renderLocs(ListItem(loc(P:Path, L:Int)) REST:List)
    => ListItem(loc(renderOut(P), L)) renderLocs(REST)

  rule locIn(LOC:Loc, .List) => false
  rule locIn(LOC:Loc, ListItem(LOC) REST:List) => true
  rule locIn(LOC1:Loc, ListItem(LOC2:Loc) REST:List) => locIn(LOC1, REST)
    requires LOC1 =/=K LOC2

  rule noDup(.List) => true
  rule noDup(ListItem(LOC:Loc) REST:List)
    => notBool locIn(LOC, REST) andBool noDup(REST)

  rule sameRendered(loc(P1:Path, L1:Int), loc(P2:Path, L2:Int))
    => (renderOut(P1) ==K renderOut(P2)) andBool (L1 ==Int L2)
endmodule

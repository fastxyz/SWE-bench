// Constructed, not machine-checked.
// Mini semantics for the export_text feature-name lookup control flow.

module MINI-EXPORT-TEXT-SYNTAX
  imports INT-SYNTAX
  imports BOOL-SYNTAX
  imports LIST-SYNTAX

  syntax Names ::= noNames | named(Int)
  syntax Tree ::= leaf | split(Int, Tree, Tree)
  syntax Exp ::= export(Tree, Names, Int)
               | visit(Tree, Int)
               | lookupName(Int)

  syntax KResult ::= Names | Tree
endmodule

module MINI-EXPORT-TEXT
  imports MINI-EXPORT-TEXT-SYNTAX
  imports INT
  imports BOOL
  imports LIST

  configuration
    <k> $PGM:Exp </k>
    <names> noNames </names>
    <maxDepth> 10 </maxDepth>
    <lookups> .List </lookups>
    <badLookup> false </badLookup>

  // Start export_text's recursive traversal at the root and depth 1.
  rule <k> export(T:Tree, NMS:Names, MAX:Int) => visit(T, 1) ... </k>
       <names> _ => NMS </names>
       <maxDepth> _ => MAX </maxDepth>
       <lookups> _ => .List </lookups>
       <badLookup> _ => false </badLookup>

  // The real exporter does not select a feature name in the truncation branch.
  rule <k> visit(_TREE:Tree, DEPTH:Int) => .K ... </k>
       <maxDepth> MAX:Int </maxDepth>
    requires DEPTH >Int MAX +Int 1

  // Leaf nodes emit leaf text and do not select a feature name.
  rule <k> visit(leaf, DEPTH:Int) => .K ... </k>
       <maxDepth> MAX:Int </maxDepth>
    requires DEPTH <=Int MAX +Int 1

  // Split nodes select a feature name, then recurse into both children.
  rule <k> visit(split(FEATURE, LEFT, RIGHT), DEPTH:Int)
           => lookupName(FEATURE) ~> visit(LEFT, DEPTH +Int 1) ~> visit(RIGHT, DEPTH +Int 1)
           ... </k>
       <maxDepth> MAX:Int </maxDepth>
    requires DEPTH <=Int MAX +Int 1

  // With no user-provided feature_names, generic labels do not index a list.
  rule <k> lookupName(FEATURE:Int) => .K ... </k>
       <names> noNames </names>
       <lookups> LS:List => ListItem(FEATURE) LS </lookups>

  // With user-provided feature_names, a valid split feature index is safe.
  rule <k> lookupName(FEATURE:Int) => .K ... </k>
       <names> named(LEN:Int) </names>
       <lookups> LS:List => ListItem(FEATURE) LS </lookups>
    requires 0 <=Int FEATURE andBool FEATURE <Int LEN

  // This rule models the IndexError-class failure V1 must make unreachable.
  rule <k> lookupName(FEATURE:Int) => .K ... </k>
       <names> named(LEN:Int) </names>
       <badLookup> false => true </badLookup>
    requires FEATURE <Int 0 orBool LEN <=Int FEATURE
endmodule

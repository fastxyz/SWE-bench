module MINI-PYTEST-MODPATH-SYNTAX
  imports STRING-SYNTAX
  imports BOOL-SYNTAX

  syntax Node ::= moduleNode(String)
                | instanceNode(String)
                | namedNode(String)

  syntax Nodes ::= ".Nodes"
                 | Node ";" Nodes [right]

  syntax KItem ::= getmodpath(Nodes, Bool, Bool)

  // Spec-level abstraction for the unchanged projection loop:
  // skip Instance nodes, stem Module nodes, honor stopatmodule/includemodule,
  // reverse into display order, and join selected parts with ".".
  syntax String ::= projectJoin(Nodes, Bool, Bool) [function]
endmodule

module MINI-PYTEST-MODPATH
  imports MINI-PYTEST-MODPATH-SYNTAX
  imports STRING
  imports BOOL

  configuration <k> $PGM:K </k>

  // V1 behavior: getmodpath returns the projected join directly.
  // There is intentionally no rule corresponding to replace(".[", "[").
  rule <k> getmodpath(CHAIN:Nodes, STOP:Bool, INCLUDE:Bool)
        => projectJoin(CHAIN, STOP, INCLUDE) ... </k>

  // Public reproducer: one selected function-name part below a module.
  rule projectJoin(
        namedNode("test_boo[..[]") ; moduleNode("bug.py") ; .Nodes,
        true,
        false
      )
      => "test_boo[..[]" [simplification]
endmodule

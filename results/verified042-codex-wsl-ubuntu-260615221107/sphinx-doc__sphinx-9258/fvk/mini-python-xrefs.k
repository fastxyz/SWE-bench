module MINI-PYTHON-XREF-SYNTAX
  imports STRING-SYNTAX

  syntax Segment  ::= atom(String) | delim(String)
  syntax Segments ::= ".Segments"
                    | Segment ";" Segments [right]

  syntax XNode ::= xref(String) | literal(String)
  syntax XNodes ::= ".XNodes"
                  | XNode ";" XNodes [right]

  syntax XNodes ::= makeXrefs(Segments) [function]
  syntax KResult ::= XNodes
endmodule

module MINI-PYTHON-XREF
  imports MINI-PYTHON-XREF-SYNTAX
  imports BOOL
  imports STRING

  configuration <k> $PGM:XNodes </k>

  rule makeXrefs(.Segments) => .XNodes
  rule makeXrefs(atom(T) ; REST) => xref(T) ; makeXrefs(REST)
    requires T =/=String ""
  rule makeXrefs(delim(D) ; REST) => literal(D) ; makeXrefs(REST)
endmodule

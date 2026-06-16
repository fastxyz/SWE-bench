// Mini semantics for the Sphinx Python-domain property type path.
// Constructed, not machine-checked.

module MINI-PYTHON-DOMAIN-SYNTAX
  imports STRING-SYNTAX

  syntax TypeOpt ::= "noType"
                   | "type" "(" String ")"

  syntax Node ::= "txt" "(" String ")"
                | "xref" "(" String ")"
                | "descAnn" "(" Nodes ")"

  syntax Nodes ::= ".Nodes"
                 | Nodes Node [left, klabel(nodesAppend)]

  syntax Command ::= "handlePropertyType" "(" TypeOpt ")"
                   | "parseAnnotation" "(" String ")"
                   | "appendPropertyType"

  syntax KResult ::= Node
endmodule

module MINI-PYTHON-DOMAIN
  imports MINI-PYTHON-DOMAIN-SYNTAX
  imports STRING

  configuration
    <k> $PGM:Command </k>
    <signode> .Nodes </signode>

  // No :type: option means PyProperty.handle_signature leaves the type suffix alone.
  rule <k> handlePropertyType(noType) => .K ... </k>

  // V1 behavior: the property type option is parsed before appending the annotation.
  rule <k> handlePropertyType(type(T)) => parseAnnotation(T) ~> appendPropertyType ... </k>
    requires T =/=String ""

  // Abstraction of sphinx.domains.python._parse_annotation for the issue's
  // documented type-token case: a type token becomes a pending Python xref.
  rule <k> parseAnnotation(T) => xref(T) ... </k>
    requires T =/=String ""

  // Append the same visible prefix as before, followed by the parsed annotation node.
  rule <k> N:Node ~> appendPropertyType => .K ... </k>
       <signode> S => S descAnn(.Nodes txt(": ") N) </signode>
endmodule

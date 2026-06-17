requires "domains.md"

module MINI-PARSER-SCOPE-SYNTAX
  imports LIST

  syntax Scope ::= "E" | "P" | "A"
  syntax Outcome ::= "ok" | "paramError"

  syntax Cmd ::= "done"
               | "enter" Scope ";" Cmd [right]
               | "exit" ";" Cmd [right]
               | "recordParamInit" ";" Cmd [right]
               | "parseArrowHead" ";" Cmd [right]
               | "parseConciseArrowBody" ";" Cmd [right]
               | "parseBlockBody" ";" Cmd [right]
               | "parseFunctionParamsWithConciseArrowDefault" ";" Cmd [right]
endmodule

module MINI-PARSER-SCOPE
  imports MINI-PARSER-SCOPE-SYNTAX
  imports LIST

  configuration
    <k> $PGM:Cmd </k>
    <stack> .List </stack>
    <outcome> ok </outcome>

  rule <k> enter S ; K => K </k>
       <stack> STACK => ListItem(S) STACK </stack>

  rule <k> exit ; K => K </k>
       <stack> ListItem(_) STACK => STACK </stack>

  rule <k> recordParamInit ; K => K </k>
       <stack> ListItem(E) STACK => ListItem(E) STACK </stack>
       <outcome> ok </outcome>

  rule <k> recordParamInit ; K => K </k>
       <stack> ListItem(P) STACK => ListItem(P) STACK </stack>
       <outcome> ok => paramError </outcome>

  rule <k> recordParamInit ; K => K </k>
       <stack> ListItem(A) STACK => ListItem(A) STACK </stack>
       <outcome> ok </outcome>

  rule <k> parseArrowHead ; K
        => enter A ; exit ; K
       </k>

  rule <k> parseConciseArrowBody ; K
        => enter E ; exit ; K
       </k>

  rule <k> parseBlockBody ; K
        => enter E ; exit ; K
       </k>

  rule <k> parseFunctionParamsWithConciseArrowDefault ; K
        => enter P ; parseArrowHead ; parseConciseArrowBody ; exit ; K
       </k>
endmodule

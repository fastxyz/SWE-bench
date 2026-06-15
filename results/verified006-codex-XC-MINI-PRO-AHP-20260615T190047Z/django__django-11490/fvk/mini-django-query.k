module MINI-DJANGO-QUERY-SYNTAX
  syntax Fields ::= ".Fields" | "nameOrder" | "order" | "explicit"
  syntax Query ::= "q" "(" Fields "," Fields ")"
  syntax Pgm ::= "compileV1" "(" Fields ")"
               | "compileOld" "(" Fields ")"
               | "done"
  syntax KResult ::= "done"
  syntax Query ::= "clone" "(" Query ")" [function]
                 | "applyValues" "(" Fields "," Query ")" [function]
endmodule

module MINI-DJANGO-QUERY
  imports MINI-DJANGO-QUERY-SYNTAX
  imports BOOL

  configuration
    <k> $PGM:Pgm </k>
    <orig> q(.Fields, .Fields) </orig>
    <compiled> q(.Fields, .Fields) </compiled>

  rule clone(Q:Query) => Q

  rule applyValues(.Fields, Q:Query) => Q
  rule applyValues(F:Fields, q(.Fields, _OLD:Fields)) => q(F, F)
    requires F =/=K .Fields
  rule applyValues(F:Fields, q(VS:Fields, SEL:Fields)) => q(VS, SEL)
    requires F =/=K .Fields andBool VS =/=K .Fields

  // V1 semantics: compile a clone and leave the original child query framed.
  rule <k> compileV1(F:Fields) => done </k>
       <orig> Q:Query </orig>
       <compiled> _ => applyValues(F, clone(Q)) </compiled>

  // Pre-fix semantics for contrast: compile by mutating the original query.
  rule <k> compileOld(F:Fields) => done </k>
       <orig> Q:Query => applyValues(F, Q) </orig>
       <compiled> _ => applyValues(F, Q) </compiled>
endmodule

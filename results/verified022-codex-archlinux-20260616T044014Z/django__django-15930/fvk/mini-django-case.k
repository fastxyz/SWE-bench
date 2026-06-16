requires "domains.md"

module MINI-DJANGO-CASE-SYNTAX
  imports STRING-SYNTAX

  syntax Params ::= ".Params"
                  | "params" "(" String ")"
                  | Params "+Params" Params [function]

  syntax Condition ::= "Full"
                     | "Empty"
                     | "Pred" "(" String "," Params ")"

  syntax Render ::= "render" "(" String "," Params ")"

  syntax Pgm ::= Render
               | "whenAsSql" "(" Condition "," String "," Params ")"
               | "caseOneAsSql" "(" Condition "," String "," Params "," String "," Params ")"
endmodule

module MINI-DJANGO-CASE
  imports MINI-DJANGO-CASE-SYNTAX
  imports STRING

  configuration <k> $PGM:Pgm </k>

  rule .Params +Params P => P
  rule P +Params .Params => P

  // A WhereNode condition that matches everything compiles to the empty SQL
  // sentinel. Inside searched CASE syntax it must be rendered as a predicate.
  rule <k> whenAsSql(Full, RESULT, RPARAMS)
        => render("WHEN 1=1 THEN " +String RESULT, RPARAMS)
       </k>

  rule <k> whenAsSql(Pred(CONDITION, CPARAMS), RESULT, RPARAMS)
        => render(
             "WHEN " +String CONDITION +String " THEN " +String RESULT,
             CPARAMS +Params RPARAMS
           )
       </k>
    requires CONDITION =/=String ""

  // Case.as_sql() catches EmptyResultSet from an impossible When and, with no
  // remaining cases in this one-case abstraction, returns the default.
  rule <k> caseOneAsSql(Empty, _RESULT, _RPARAMS, DEFAULT, DPARAMS)
        => render(DEFAULT, DPARAMS)
       </k>

  rule <k> caseOneAsSql(Full, RESULT, RPARAMS, DEFAULT, DPARAMS)
        => render(
             "CASE WHEN 1=1 THEN " +String RESULT +String " ELSE " +String DEFAULT +String " END",
             RPARAMS +Params DPARAMS
           )
       </k>

  rule <k> caseOneAsSql(Pred(CONDITION, CPARAMS), RESULT, RPARAMS, DEFAULT, DPARAMS)
        => render(
             "CASE WHEN " +String CONDITION +String " THEN " +String RESULT +String " ELSE " +String DEFAULT +String " END",
             CPARAMS +Params RPARAMS +Params DPARAMS
           )
       </k>
    requires CONDITION =/=String ""
endmodule

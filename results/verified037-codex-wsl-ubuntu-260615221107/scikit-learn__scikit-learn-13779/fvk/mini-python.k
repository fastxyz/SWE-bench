module MINI-PYTHON-VOTING-SYNTAX
  imports BOOL-SYNTAX
  imports ID-SYNTAX

  // Estimator record used by the formal model:
  // est(name, dropped, supportsSampleWeight)
  syntax Est ::= "est" "(" Id "," Bool "," Bool ")"
  syntax Ests ::= ".Ests"
                | Est ";;" Ests [right]
  syntax Names ::= ".Names"
                 | Id "::" Names [right]

  syntax Cmd ::= "fitVoting" "(" Ests "," Bool ")"
               | "fitActive" "(" Ests "," Bool ")"

  syntax Result ::= "ok" "(" Names "," Names ")"
                  | "errorUnsupported" "(" Id ")"
                  | "errorAllNone"

  syntax KResult ::= Result
endmodule

module MINI-PYTHON-VOTING
  imports MINI-PYTHON-VOTING-SYNTAX
  imports BOOL

  configuration <k> $PGM:Cmd </k>

  syntax Ests ::= "active" "(" Ests ")" [function]
  rule active(.Ests) => .Ests
  rule active(est(N:Id, true, S:Bool) ;; ES:Ests) => active(ES)
  rule active(est(N:Id, false, S:Bool) ;; ES:Ests)
    => est(N, false, S) ;; active(ES)

  syntax Bool ::= "isEmpty" "(" Ests ")" [function]
  rule isEmpty(.Ests) => true
  rule isEmpty(E:Est ;; ES:Ests) => false

  syntax Bool ::= "hasUnsupported" "(" Ests ")" [function]
  rule hasUnsupported(.Ests) => false
  rule hasUnsupported(est(N:Id, false, false) ;; ES:Ests) => true
  rule hasUnsupported(est(N:Id, false, true) ;; ES:Ests)
    => hasUnsupported(ES)

  syntax Id ::= "firstUnsupported" "(" Ests ")" [function]
  rule firstUnsupported(est(N:Id, false, false) ;; ES:Ests) => N
  rule firstUnsupported(est(N:Id, false, true) ;; ES:Ests)
    => firstUnsupported(ES)
    requires hasUnsupported(ES)

  syntax Names ::= "names" "(" Ests ")" [function]
  rule names(.Ests) => .Names
  rule names(est(N:Id, D:Bool, S:Bool) ;; ES:Ests) => N :: names(ES)

  rule <k> fitVoting(ES:Ests, SW:Bool)
        => fitActive(active(ES), SW)
       </k>

  rule <k> fitActive(.Ests, SW:Bool) => errorAllNone </k>

  rule <k> fitActive(ES:Ests, true)
        => errorUnsupported(firstUnsupported(ES))
       </k>
    requires hasUnsupported(ES)

  rule <k> fitActive(ES:Ests, true)
        => ok(names(ES), names(ES))
       </k>
    requires notBool isEmpty(ES) andBool notBool hasUnsupported(ES)

  rule <k> fitActive(ES:Ests, false)
        => ok(names(ES), names(ES))
       </k>
    requires notBool isEmpty(ES)
endmodule

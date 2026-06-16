module MINI-DJANGO-AGGREGATE-SYNTAX
  imports BOOL-SYNTAX

  syntax Mode ::= "terminal" | "nonTerminal"
  syntax Expr ::= "agg" "(" Bool ")"
                | "coalesce" "(" Expr "," Bool ")"
                | "resolve" "(" Bool "," Mode ")"      [function]
                | "resolveBefore" "(" Bool "," Mode ")" [function]
  syntax Outcome ::= "valid" | "invalid"
                   | "plan" "(" Bool "," Expr ")"       [function]
  syntax Bool ::= "isTerminal" "(" Mode ")" [function]
                | "isSummary" "(" Expr ")"  [function]
  syntax KResult ::= Expr | Outcome | Bool
endmodule

module MINI-DJANGO-AGGREGATE
  imports MINI-DJANGO-AGGREGATE-SYNTAX
  imports BOOL

  configuration <k> $PGM:K </k>

  // terminal models QuerySet.aggregate(...), which calls add_annotation(..., is_summary=True).
  rule isTerminal(terminal) => true
  rule isTerminal(nonTerminal) => false

  // V1 behavior: the internal Coalesce wrapper preserves the resolved aggregate summary flag.
  rule resolve(false, M:Mode) => agg(isTerminal(M))
  rule resolve(true,  M:Mode) => coalesce(agg(isTerminal(M)), isTerminal(M))

  // Pre-fix behavior: Aggregate.default generated a Coalesce wrapper with the class default
  // is_summary = false, regardless of the wrapped terminal aggregate.
  rule resolveBefore(false, M:Mode) => agg(isTerminal(M))
  rule resolveBefore(true,  M:Mode) => coalesce(agg(isTerminal(M)), false)

  rule isSummary(agg(B:Bool)) => B
  rule isSummary(coalesce(_:Expr, B:Bool)) => B

  // The first Boolean is whether existing annotations force a subquery. Without a subquery,
  // this issue's empty outer SELECT path is not entered.
  rule plan(false, _:Expr) => valid
  rule plan(true, E:Expr) => valid requires isSummary(E)
  rule plan(true, E:Expr) => invalid requires notBool isSummary(E)
endmodule

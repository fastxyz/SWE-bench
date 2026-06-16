module MINI-PYTHON-SYNTAX
  imports BOOL-SYNTAX
  imports ID-SYNTAX

  syntax Conn ::= "AND" | "OR"

  // Abstract child shapes for the part of Q relevant to this issue.
  syntax Child ::= ".Child"
                 | "lookupLeaf"
                 | "exprLeaf"
                 | "nestedEmptyQLeaf"
                 | "both(" Child "," Child ")"

  syntax Operand ::= "emptyQ"
                   | "lookupQ"
                   | "exprQ"
                   | "andLookupExprQ"
                   | "orLookupExprQ"
                   | "condExpr"
                   | "nonCond"
                   | "wrap(" Operand ")"        [function]
                   | "clone(" Operand ")"       [function]
                   | "reconstruct(" Decon ")"   [function]

  syntax Decon ::= "argsExpr"
                 | "kwargsLookup"
                 | "argsNestedEmptyQ"
                 | "deconstructError"
                 | "deconstructQ(" Operand ")" [function]

  syntax Result ::= "ok(" Operand ")"
                  | "typeError(" Operand ")"
                  | "combine(" Operand "," Operand "," Conn ")"  [function]
                  | "combineQ(" Operand "," Operand "," Conn ")" [function]

  syntax Prog ::= Operand | Decon | Result
  syntax KResult ::= Operand | Decon | Result
endmodule

module MINI-PYTHON
  imports MINI-PYTHON-SYNTAX
  imports BOOL

  configuration <k> $PGM:Prog </k>

  syntax Bool ::= isConditional(Operand) [function]
  rule isConditional(emptyQ) => true
  rule isConditional(lookupQ) => true
  rule isConditional(exprQ) => true
  rule isConditional(andLookupExprQ) => true
  rule isConditional(orLookupExprQ) => true
  rule isConditional(condExpr) => true
  rule isConditional(nonCond) => false

  syntax Bool ::= isQ(Operand) [function]
  rule isQ(emptyQ) => true
  rule isQ(lookupQ) => true
  rule isQ(exprQ) => true
  rule isQ(andLookupExprQ) => true
  rule isQ(orLookupExprQ) => true
  rule isQ(condExpr) => false
  rule isQ(nonCond) => false

  syntax Bool ::= isEmptyQ(Operand) [function]
  rule isEmptyQ(emptyQ) => true
  rule isEmptyQ(lookupQ) => false
  rule isEmptyQ(exprQ) => false
  rule isEmptyQ(andLookupExprQ) => false
  rule isEmptyQ(orLookupExprQ) => false
  rule isEmptyQ(condExpr) => false
  rule isEmptyQ(nonCond) => false

  rule wrap(Q:Operand) => Q
    requires isQ(Q)
  rule wrap(condExpr) => exprQ

  rule deconstructQ(exprQ) => argsExpr
  rule deconstructQ(lookupQ) => kwargsLookup
  rule deconstructQ(emptyQ) => argsNestedEmptyQ

  rule reconstruct(argsExpr) => exprQ
  rule reconstruct(kwargsLookup) => lookupQ
  rule reconstruct(argsNestedEmptyQ) => emptyQ

  rule clone(Q:Operand) => reconstruct(deconstructQ(Q))
    requires isQ(Q)

  rule combine(S:Operand, O:Operand, C:Conn) => typeError(O)
    requires notBool isConditional(O)
  rule combine(S:Operand, O:Operand, C:Conn) => combineQ(S, wrap(O), C)
    requires isConditional(O)

  rule combineQ(S:Operand, O:Operand, C:Conn) => ok(clone(S))
    requires isEmptyQ(O)
  rule combineQ(S:Operand, O:Operand, C:Conn) => ok(clone(O))
    requires notBool isEmptyQ(O) andBool isEmptyQ(S)
  rule combineQ(lookupQ, exprQ, AND) => ok(andLookupExprQ)
  rule combineQ(lookupQ, exprQ, OR) => ok(orLookupExprQ)
endmodule

module MINI-SYMPY-QUANTUM-SYNTAX
  imports INT-SYNTAX
  imports ID-SYNTAX

  syntax QExpr ::= op(Id)
                 | idOp(Int)
                 | dagger(QExpr)
                 | nonOp(Id)
                 | mul(QExpr, QExpr)

  syntax QCmd ::= operatorMul(QExpr, QExpr)
                | daggerMul(QExpr, QExpr)
                | identityMul(QExpr, QExpr)

  syntax KResult ::= QExpr
endmodule

module MINI-SYMPY-QUANTUM
  imports MINI-SYMPY-QUANTUM-SYNTAX
  imports INT

  configuration <k> $PGM:QCmd </k>

  // Existing Operator.__mul__: Operator * IdentityOperator -> Operator.
  rule <k> operatorMul(op(A:Id), idOp(N:Int)) => op(A) </k>
  rule <k> operatorMul(X:QExpr, Y:QExpr) => mul(X, Y) </k> [owise]

  // V1 Dagger.__mul__: Dagger(Operator) * IdentityOperator -> Dagger(Operator).
  rule <k> daggerMul(dagger(op(A:Id)), idOp(N:Int)) => dagger(op(A)) </k>
  rule <k> daggerMul(X:QExpr, Y:QExpr) => mul(X, Y) </k> [owise]

  // IdentityOperator.__mul__: IdentityOperator * operator-valued target -> target.
  rule <k> identityMul(idOp(N:Int), op(A:Id)) => op(A) </k>
  rule <k> identityMul(idOp(N:Int), dagger(op(A:Id))) => dagger(op(A)) </k>
  rule <k> identityMul(idOp(N:Int), X:QExpr) => mul(idOp(N), X) </k> [owise]
endmodule

// Constructed, not machine-checked.
// Minimal abstract K fragment for the EvaluateFalseTransformer comparison
// proof. This models only the observable property under audit: supported
// Python comparison operators are rewritten to SymPy constructor calls carrying
// evaluate=False.

module MINI-SYMPY-PARSER-SYNTAX
  imports BOOL
  imports INT
  imports STRING

  syntax Op ::= "EqOp" | "NotEqOp" | "LtOp" | "LtEOp" | "GtOp" | "GtEOp"
              | "UnsupportedOp"

  syntax Exp ::= Leaf(String)
               | Compare(Exp, Ops, Exps)
               | RelCall(String, Exp, Exp, Bool)
               | AndCall(Exps, Bool)

  syntax Ops ::= ".Ops" | Op "," Ops
  syntax Exps ::= ".Exps" | Exp "," Exps
endmodule

module MINI-SYMPY-PARSER
  imports MINI-SYMPY-PARSER-SYNTAX

  configuration <k> $PGM:K </k>

  syntax String ::= relName(Op) [function]
  rule relName(EqOp) => "Eq"
  rule relName(NotEqOp) => "Ne"
  rule relName(LtOp) => "Lt"
  rule relName(LtEOp) => "Le"
  rule relName(GtOp) => "Gt"
  rule relName(GtEOp) => "Ge"

  syntax Bool ::= supported(Op) [function]
  rule supported(EqOp) => true
  rule supported(NotEqOp) => true
  rule supported(LtOp) => true
  rule supported(LtEOp) => true
  rule supported(GtOp) => true
  rule supported(GtEOp) => true
  rule supported(UnsupportedOp) => false

  // Abstract recursive visit. Leaves stand for already-transformed operands in
  // this fragment; the existing transformer rules for BinOp/Call are outside
  // this proof slice.
  syntax Exp ::= visit(Exp) [function]
  rule visit(Leaf(S)) => Leaf(S)

  syntax Exps ::= pairwise(Exp, Ops, Exps) [function]
  rule pairwise(L, OP , .Ops, R , .Exps)
    => RelCall(relName(OP), visit(L), visit(R), false)
    requires supported(OP)
  rule pairwise(L, OP , OPS, R , RS)
    => RelCall(relName(OP), visit(L), visit(R), false) , pairwise(R, OPS, RS)
    requires supported(OP)

  syntax Exp ::= visitCompare(Exp) [function]
  rule visitCompare(Compare(L, OP , .Ops, R , .Exps))
    => RelCall(relName(OP), visit(L), visit(R), false)
    requires supported(OP)
  rule visitCompare(Compare(L, OP , OPS, R , RS))
    => AndCall(pairwise(L, OP , OPS, R , RS), false)
    requires supported(OP)
endmodule


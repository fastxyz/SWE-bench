// Constructed, not machine-checked.
// Minimal K fragment for the audited Product._eval_product additive branch.

module MINI-SYMPY-PRODUCT-SYNTAX
  imports BOOL-SYNTAX

  syntax EvalRes ::= "none"
                   | "number"
                   | "nonnumber"
                   | "quotient" "(" EvalRes "," EvalRes ")"

  syntax Outcome ::= "unevaluated"
                   | "evaluated" "(" EvalRes ")"

  syntax Cmd ::= "addProduct" "(" EvalRes "," EvalRes ")"
               | "productDoit" "(" EvalRes ")"

  syntax KResult ::= EvalRes | Outcome
endmodule

module MINI-SYMPY-PRODUCT
  imports MINI-SYMPY-PRODUCT-SYNTAX
  imports BOOL
  imports K-EQUAL

  configuration <k> $PGM:Cmd </k>

  syntax Bool ::= "isNumber" "(" EvalRes ")" [function]
  rule isNumber(none) => false
  rule isNumber(number) => true
  rule isNumber(nonnumber) => false
  rule isNumber(quotient(_:EvalRes, _:EvalRes)) => false

  rule <k> addProduct(_:EvalRes, none) => none </k> [label(ADD-Q-NONE)]
  rule <k> addProduct(_:EvalRes, number) => none </k> [label(ADD-Q-NUMBER)]
  rule <k> addProduct(none, Q:EvalRes) => none </k>
    requires notBool isNumber(Q)
    [label(ADD-P-NONE)]
  rule <k> addProduct(P:EvalRes, Q:EvalRes) => quotient(P, Q) </k>
    requires notBool isNumber(Q) andBool notBool (P ==K none)
    [label(ADD-RATIONAL)]

  rule <k> productDoit(none) => unevaluated </k> [label(DOIT-UNEVALUATED)]
  rule <k> productDoit(R:EvalRes) => evaluated(R) </k>
    requires notBool (R ==K none)
    [label(DOIT-EVALUATED)]
endmodule


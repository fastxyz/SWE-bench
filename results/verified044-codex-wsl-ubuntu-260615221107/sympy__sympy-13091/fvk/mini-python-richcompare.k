module MINI-PYTHON-RICHCOMPARE-SYNTAX
  imports BOOL-SYNTAX

  syntax Cmp ::= "Eq" | "Ne" | "Lt" | "Le" | "Gt" | "Ge"

  syntax Result ::= "RTrue"
                  | "RFalse"
                  | "RBool"
                  | "RNotImplemented"
                  | "RTypeError"

  syntax BasicCase ::= "BasicSameType"
                     | "BasicUnsympifiable"
                     | "BasicDifferentType"

  syntax OrderCase ::= "OrderValid"
                     | "OrderUnsympifiable"
                     | "OrderInvalidComplexOrNaN"

  syntax NumCase ::= "NumKnown"
                   | "NumUnknown"
                   | "NumNonNumberBasic"

  syntax SingletonCase ::= "SingletonSame"
                         | "SingletonOtherNumber"
                         | "SingletonUnsupported"

  syntax Exp ::= "basicEq" "(" BasicCase ")"
               | "basicNe" "(" BasicCase ")"
               | "exprOrder" "(" Cmp "," OrderCase ")"
               | "numberEq" "(" NumCase ")"
               | "numberNe" "(" NumCase ")"
               | "singletonEq" "(" SingletonCase ")"
               | "singletonNe" "(" SingletonCase ")"
               | "pyEq" "(" Result "," Result ")"

  syntax KResult ::= Result
endmodule

module MINI-PYTHON-RICHCOMPARE
  imports MINI-PYTHON-RICHCOMPARE-SYNTAX

  configuration <k> $PGM:Exp </k>

  // Basic.__eq__ result category.
  rule <k> basicEq(BasicSameType) => RBool ... </k>
  rule <k> basicEq(BasicUnsympifiable) => RNotImplemented ... </k>
  rule <k> basicEq(BasicDifferentType) => RNotImplemented ... </k>

  // Basic.__ne__ mirrors NotImplemented rather than negating it.
  rule <k> basicNe(BasicSameType) => RBool ... </k>
  rule <k> basicNe(BasicUnsympifiable) => RNotImplemented ... </k>
  rule <k> basicNe(BasicDifferentType) => RNotImplemented ... </k>

  // Expr ordering result categories.
  rule <k> exprOrder(_:Cmp, OrderValid) => RBool ... </k>
  rule <k> exprOrder(_:Cmp, OrderUnsympifiable) => RNotImplemented ... </k>
  rule <k> exprOrder(_:Cmp, OrderInvalidComplexOrNaN) => RTypeError ... </k>

  // Core numeric override result categories.
  rule <k> numberEq(NumKnown) => RBool ... </k>
  rule <k> numberEq(NumUnknown) => RNotImplemented ... </k>
  rule <k> numberEq(NumNonNumberBasic) => RNotImplemented ... </k>
  rule <k> numberNe(NumKnown) => RBool ... </k>
  rule <k> numberNe(NumUnknown) => RNotImplemented ... </k>
  rule <k> numberNe(NumNonNumberBasic) => RNotImplemented ... </k>

  // Numeric singleton equality preserves known-number behavior and delegates unsupported operands.
  rule <k> singletonEq(SingletonSame) => RTrue ... </k>
  rule <k> singletonEq(SingletonOtherNumber) => RFalse ... </k>
  rule <k> singletonEq(SingletonUnsupported) => RNotImplemented ... </k>
  rule <k> singletonNe(SingletonSame) => RFalse ... </k>
  rule <k> singletonNe(SingletonOtherNumber) => RTrue ... </k>
  rule <k> singletonNe(SingletonUnsupported) => RNotImplemented ... </k>

  // Python equality dispatch abstraction.
  rule <k> pyEq(RTrue,  _:Result) => RTrue ... </k>
  rule <k> pyEq(RFalse, _:Result) => RFalse ... </k>
  rule <k> pyEq(RBool,  _:Result) => RBool ... </k>
  rule <k> pyEq(RNotImplemented, RTrue) => RTrue ... </k>
  rule <k> pyEq(RNotImplemented, RFalse) => RFalse ... </k>
  rule <k> pyEq(RNotImplemented, RBool) => RBool ... </k>
  rule <k> pyEq(RNotImplemented, RNotImplemented) => RFalse ... </k>
endmodule

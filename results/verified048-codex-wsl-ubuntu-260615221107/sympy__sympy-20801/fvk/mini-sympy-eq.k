module MINI-SYMPY-EQ-SYNTAX
  imports BOOL-SYNTAX

  syntax FloatSelf ::= "floatZero" | "floatNonZero"
  syntax Obj ::= "symFalse" | "symTrue"
               | "pyFalse" | "pyTrue"
               | "numZero" | "numNonZero"
               | "nonNumber"
               | "unsympifiable"
  syntax EqResult ::= "eqTrue" | "eqFalse" | "notImplemented"

  syntax Bool ::= isSympyBoolean(Obj) [function]
                | isTruthy(Obj) [function]
                | sympifies(Obj) [function]
  syntax EqResult ::= floatEq(FloatSelf, Obj) [function]
endmodule

module MINI-SYMPY-EQ
  imports MINI-SYMPY-EQ-SYNTAX
  imports BOOL

  configuration <k> $PGM:EqResult </k>

  rule isSympyBoolean(symFalse) => true
  rule isSympyBoolean(symTrue) => true
  rule isSympyBoolean(_) => false [owise]

  rule sympifies(unsympifiable) => false
  rule sympifies(_) => true [owise]

  rule isTruthy(symFalse) => false
  rule isTruthy(pyFalse) => false
  rule isTruthy(numZero) => false
  rule isTruthy(_) => true [owise]

  // V1 guard: already-SymPy Booleans are rejected before sympification.
  rule floatEq(F:FloatSelf, O:Obj) => eqFalse
    requires isSympyBoolean(O)

  // Unsympifiable non-Boolean operands keep the NotImplemented frame.
  rule floatEq(F:FloatSelf, O:Obj) => notImplemented
    requires notBool isSympyBoolean(O) andBool notBool sympifies(O)

  // Existing zero-Float shortcut for non-SymPy-Boolean operands.
  rule floatEq(floatZero, O:Obj) => eqTrue
    requires notBool isSympyBoolean(O) andBool sympifies(O) andBool notBool isTruthy(O)
  rule floatEq(floatZero, O:Obj) => eqFalse
    requires notBool isSympyBoolean(O) andBool sympifies(O) andBool isTruthy(O)

  // Existing post-sympification Boolean guard and nonzero frame.
  rule floatEq(floatNonZero, O:Obj) => eqFalse
    requires notBool isSympyBoolean(O)
endmodule

module MINI-PYTHON-HUBER-SYNTAX
  imports INT-SYNTAX
  imports BOOL-SYNTAX

  // Minimal value model for the Huber dtype-safety slice.
  syntax Storage ::= "dense" | "csr"
  syntax DType ::= "bool" | "int64" | "float64" | "float32" | "float16"
                 | "unknownDType"
  syntax Matrix ::= "matrix" "(" Storage "," DType "," Int "," Int ")"
  syntax Error ::= "noError" | "boolNegativeTypeError"

  syntax Stmt ::= "fitV1" "(" Matrix ")"
                | "fitV0" "(" Matrix ")"
                | "gradientSquared" "(" Matrix ")"

  syntax KResult ::= Matrix | Error
endmodule

module MINI-PYTHON-HUBER
  imports MINI-PYTHON-HUBER-SYNTAX
  imports INT
  imports BOOL

  configuration
    <k> $PGM:Stmt </k>
    <validatedDType> unknownDType </validatedDType>
    <error> noError </error>

  syntax Bool ::= isFloatDType(DType) [function]
  rule isFloatDType(float64) => true
  rule isFloatDType(float32) => true
  rule isFloatDType(float16) => true
  rule isFloatDType(bool) => false
  rule isFloatDType(int64) => false
  rule isFloatDType(unknownDType) => false

  // V1 model: check_X_y(..., dtype=FLOAT_DTYPES). Existing floating dtypes
  // are accepted as-is; non-floating numeric dtypes are converted to float64.
  rule
    <k> fitV1(matrix(S:Storage, DT:DType, R:Int, C:Int))
      => gradientSquared(matrix(S, DT, R, C)) ... </k>
    <validatedDType> _ => DT </validatedDType>
    requires isFloatDType(DT)

  rule
    <k> fitV1(matrix(S:Storage, DT:DType, R:Int, C:Int))
      => gradientSquared(matrix(S, float64, R, C)) ... </k>
    <validatedDType> _ => float64 </validatedDType>
    requires notBool isFloatDType(DT)

  // Counterfactual V0 model: default dtype="numeric" preserves bool X.
  rule
    <k> fitV0(matrix(S:Storage, DT:DType, R:Int, C:Int))
      => gradientSquared(matrix(S, DT, R, C)) ... </k>
    <validatedDType> _ => DT </validatedDType>

  // The reported failure: unary minus on a boolean X slice is not defined.
  rule
    <k> gradientSquared(matrix(S:Storage, bool, R:Int, C:Int)) => .K ... </k>
    <error> noError => boolNegativeTypeError </error>

  // Floating X makes the unary-minus gradient operation dtype-safe.
  rule
    <k> gradientSquared(matrix(S:Storage, DT:DType, R:Int, C:Int)) => .K ... </k>
    requires isFloatDType(DT)
endmodule

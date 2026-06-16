// Minimal codegen semantics for the sympy__sympy-16792 FVK pass.
// Status: constructed, not machine-checked.

module MINI-CODEGEN-SYNTAX
  imports INT-SYNTAX
  imports BOOL-SYNTAX

  syntax Name
  syntax Shape ::= "shape2" "(" Int "," Int ")" | "noShape"
  syntax Dims  ::= "dims2" "(" Int "," Int ")" | "noDims"

  syntax Arg ::= "matrix" "(" Name "," Shape ")"
               | "scalar" "(" Name ")"
               | "indexed" "(" Name "," Shape ")"

  syntax Existing ::= "knownArg" "(" ArgObj ")" | "missingArg"
  syntax ArrayInfo ::= "knownArray" "(" Shape ")" | "unknownArray"

  syntax ArgObj ::= "input" "(" Arg "," Dims ")"

  syntax CType ::= "pointerC" | "scalarC"
  syntax PyxType ::= "ndarrayPyx" | "scalarPyx"
  syntax CallKind ::= "dataPointerCall" | "scalarCall"

  syntax Dims ::= "dimsFromShape" "(" Shape ")" [function]
                | "metadata" "(" Arg "," ArrayInfo ")" [function]
  syntax ArgObj ::= "redundantArg" "(" Arg "," Existing "," ArrayInfo ")" [function]
  syntax CType ::= "cPrototype" "(" ArgObj ")" [function]
  syntax PyxType ::= "cythonPrototype" "(" ArgObj ")" [function]
  syntax CallKind ::= "cythonCall" "(" ArgObj ")" [function]
  syntax Bool ::= "hasDims" "(" Dims ")" [function]

  syntax KResult ::= Dims | ArgObj | CType | PyxType | CallKind
endmodule

module MINI-CODEGEN
  imports MINI-CODEGEN-SYNTAX
  imports INT
  imports BOOL

  configuration <k> $PGM:K </k>

  rule dimsFromShape(shape2(R:Int, C:Int)) => dims2(R -Int 1, C -Int 1)
  rule hasDims(noDims) => false
  rule hasDims(dims2(R:Int, C:Int)) => true

  rule metadata(A:Arg, knownArray(S:Shape)) => dimsFromShape(S)
    requires S =/=K noShape

  rule metadata(matrix(N:Name, S:Shape), unknownArray) => dimsFromShape(S)
    requires S =/=K noShape

  rule metadata(scalar(N:Name), unknownArray) => noDims
  rule metadata(indexed(N:Name, noShape), unknownArray) => noDims

  rule redundantArg(A:Arg, knownArg(OBJ:ArgObj), INFO:ArrayInfo) => OBJ
  rule redundantArg(A:Arg, missingArg, INFO:ArrayInfo) => input(A, metadata(A, INFO))

  rule cPrototype(input(A:Arg, D:Dims)) => pointerC
    requires hasDims(D)
  rule cPrototype(input(A:Arg, noDims)) => scalarC

  rule cythonPrototype(input(A:Arg, D:Dims)) => ndarrayPyx
    requires hasDims(D)
  rule cythonPrototype(input(A:Arg, noDims)) => scalarPyx

  rule cythonCall(input(A:Arg, D:Dims)) => dataPointerCall
    requires hasDims(D)
  rule cythonCall(input(A:Arg, noDims)) => scalarCall
endmodule

// Minimal constructor-selection semantics for the audited Min/Max change.
// Constructed, not machine-checked.
//
// This is intentionally not a full Python or SymPy semantics. It models the
// property under audit: whether the MinMaxBase constructor dispatches empty
// argument lists to the class identity and leaves non-empty lists on the
// original non-empty constructor path.

module MINI-PYTHON-SYNTAX
  imports BOOL-SYNTAX
  imports ID-SYNTAX

  syntax Class ::= "MinCls" | "MaxCls"
  syntax Value ::= "oo" | "negOo" | "tailResult" "(" Class "," Args ")"
  syntax Args  ::= ".Args" | "consArg" "(" Id "," Args ")"
  syntax Exp   ::= "construct" "(" Class "," Args ")"

  syntax KResult ::= Value
endmodule

module MINI-PYTHON
  imports MINI-PYTHON-SYNTAX
  imports BOOL

  configuration <k> $PGM:Exp </k>

  syntax Value ::= "identity" "(" Class ")" [function]
  rule identity(MinCls) => oo
  rule identity(MaxCls) => negOo

  syntax Bool ::= "isEmptyArgs" "(" Args ")" [function]
  rule isEmptyArgs(.Args) => true
  rule isEmptyArgs(consArg(_, _)) => false

  // V1 empty-argument branch:
  //     if not args:
  //         return cls.identity
  rule <k> construct(C:Class, .Args) => identity(C) </k>

  // Abstracted original path for non-empty arguments. The full SymPy
  // constructor is outside this mini semantics, but the frame property under
  // audit is that V1 still reaches the same non-empty tail code.
  rule <k> construct(C:Class, AS:Args) => tailResult(C, AS) </k>
    requires notBool isEmptyArgs(AS)
endmodule

module MINI-PYCODE-SYNTAX
  imports STRING-SYNTAX
  imports BOOL-SYNTAX
  imports SET-SYNTAX

  syntax Expr ::= Sym(String)
                | Fun(String, Args)

  syntax Args ::= ".Args"
                | Expr "," Args

  syntax Codes ::= ".Codes"
                 | String "," Codes

  syntax Task ::= print(Expr)

  syntax KResult ::= String
endmodule

module MINI-PYCODE
  imports MINI-PYCODE-SYNTAX
  imports STRING
  imports BOOL
  imports SET

  configuration
    <k> $PGM:Task </k>
    <unsupported> .Set </unsupported>

  syntax Bool ::= isKnown(String) [function]
  rule isKnown("Abs") => true
  rule isKnown("Max") => true
  rule isKnown("Min") => true
  rule isKnown(_:String) => false [owise]

  syntax String ::= knownName(String) [function]
  rule knownName("Abs") => "abs"
  rule knownName("Max") => "max"
  rule knownName("Min") => "min"

  syntax String ::= printPure(Expr) [function]
  rule printPure(Sym(S:String)) => S
  rule printPure(Fun(F:String, AS:Args))
    => knownName(F) +String "(" +String joinCodes(printArgs(AS)) +String ")"
    requires isKnown(F)
  rule printPure(Fun(F:String, AS:Args))
    => F +String "(" +String joinCodes(printArgs(AS)) +String ")"
    requires notBool isKnown(F)

  syntax Codes ::= printArgs(Args) [function]
  rule printArgs(.Args) => .Codes
  rule printArgs(E:Expr , AS:Args) => printPure(E) , printArgs(AS)

  syntax String ::= joinCodes(Codes) [function]
  rule joinCodes(.Codes) => ""
  rule joinCodes(C:String , .Codes) => C
  rule joinCodes(C:String , CS:Codes) => C +String ", " +String joinCodes(CS)

  rule <k> print(Sym(S:String)) => S ... </k>
  rule <k> print(Fun(F:String, AS:Args))
    => knownName(F) +String "(" +String joinCodes(printArgs(AS)) +String ")"
    ... </k>
    requires isKnown(F)
  rule <k> print(Fun(F:String, AS:Args))
    => F +String "(" +String joinCodes(printArgs(AS)) +String ")"
    ... </k>
    <unsupported> U:Set => U SetItem(F) </unsupported>
    requires notBool isKnown(F)
endmodule

module MINI-RUFF-LOGICAL-LINES-SYNTAX
  imports INT-SYNTAX
  imports BOOL-SYNTAX

  syntax Token ::= typeTok | classTok | defTok | asyncTok | nameTok
                 | equalTok | lparTok | rparTok | lsqbTok | rsqbTok
                 | commaTok | colonTok | newlineTok | otherTok

  syntax Tokens ::= ".Tokens" [klabel(noTokens)]
                  | Token "," Tokens [right, klabel(tokenCons)]

  syntax TPState ::= beforeTypeParams
                   | inTypeParams(Int)
                   | typeParamsEnded

  syntax DefState ::= notInDefinition
                    | inClass(TPState)
                    | inFunction(TPState)
                    | inTypeAlias(TPState)

  syntax KItem ::= scan(Tokens)

  syntax Bool ::= isInTypeParams(DefState) [function]
                | isE252MissingBranch(DefState, Int, Bool) [function]

  syntax TPState ::= visitTP(Bool, TPState, Token) [function]
  syntax DefState ::= visit(DefState, Token) [function]
                    | scanState(DefState, Tokens) [function]
endmodule

module MINI-RUFF-LOGICAL-LINES
  imports MINI-RUFF-LOGICAL-LINES-SYNTAX
  imports INT
  imports BOOL

  configuration
    <k> $PGM:K </k>
    <state> notInDefinition </state>

  rule <k> scan(.Tokens) => .K ... </k>
  rule <k> scan(T:Token , TS:Tokens) => scan(TS) ... </k>
       <state> S:DefState => visit(S, T) </state>

  rule isInTypeParams(inClass(inTypeParams(N:Int))) => true
  rule isInTypeParams(inFunction(inTypeParams(N:Int))) => true
  rule isInTypeParams(inTypeAlias(inTypeParams(N:Int))) => true
  rule isInTypeParams(S:DefState) => false [owise]

  rule isE252MissingBranch(S:DefState, P:Int, ANNOTATED:Bool)
    => isInTypeParams(S) orBool (ANNOTATED andBool (P ==Int 1))

  rule visit(notInDefinition, typeTok) => inTypeAlias(beforeTypeParams)
  rule visit(notInDefinition, classTok) => inClass(beforeTypeParams)
  rule visit(notInDefinition, defTok) => inFunction(beforeTypeParams)
  rule visit(notInDefinition, T:Token) => notInDefinition [owise]

  rule visit(inClass(TPS:TPState), T:Token) => inClass(visitTP(false, TPS, T))
  rule visit(inFunction(TPS:TPState), T:Token) => inFunction(visitTP(false, TPS, T))
  rule visit(inTypeAlias(TPS:TPState), T:Token) => inTypeAlias(visitTP(true, TPS, T))

  // V2/V1 behavior under audit: a type alias assignment `=` before any
  // type-parameter `[` proves the alias has no explicit type parameters.
  rule visitTP(true, beforeTypeParams, equalTok) => typeParamsEnded

  // Existing behavior: `(` before type parameters ends the type-parameter window
  // for class/function definitions, and is harmless for invalid type aliases.
  rule visitTP(ISALIAS:Bool, beforeTypeParams, lparTok) => typeParamsEnded

  rule visitTP(ISALIAS:Bool, beforeTypeParams, lsqbTok) => inTypeParams(0)
  rule visitTP(ISALIAS:Bool, inTypeParams(N:Int), lsqbTok) => inTypeParams(N +Int 1)
  rule visitTP(ISALIAS:Bool, inTypeParams(0), rsqbTok) => typeParamsEnded
  rule visitTP(ISALIAS:Bool, inTypeParams(N:Int), rsqbTok) => inTypeParams(N -Int 1)
    requires N >Int 0
  rule visitTP(ISALIAS:Bool, TPS:TPState, T:Token) => TPS [owise]

  rule scanState(S:DefState, .Tokens) => S
  rule scanState(S:DefState, T:Token , TS:Tokens) => scanState(visit(S, T), TS)
endmodule

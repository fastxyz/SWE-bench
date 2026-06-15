// Constructed FVK artifact, not machine-checked in this session.
//
// This is a deliberately small semantics for the QDP command-classification
// fragment affected by astropy/io/ascii/qdp.py. It models a tokenized QDP line,
// not full Python or full regular-expression execution. The observable property
// under verification, command keyword casing, remains explicit via ciEq.

module MINI-QDP-SYNTAX
  imports INT-SYNTAX
  imports STRING-SYNTAX
  imports BOOL-SYNTAX

  syntax Cols ::= ".Cols"
                | Int Cols [right]

  syntax Line ::= readErr(String, String, Cols)
                | dataLine(Int)
                | commentLine
                | newLine
                | invalidLine

  syntax LineType ::= "command"
                    | "data"
                    | "comment"
                    | "new"
                    | "error"

  syntax QdpExp ::= lineType(Line)
                  | errKey(Line)

  syntax KResult ::= LineType | String | Bool
endmodule

module MINI-QDP
  imports MINI-QDP-SYNTAX
  imports INT
  imports STRING
  imports BOOL

  configuration <k> $PGM:QdpExp </k>

  // Abstract ASCII case-insensitive equality over command tokens.
  // The spec uses ciEq in preconditions, so the proof remains about the case
  // axis instead of collapsing READ/read into one opaque token.
  syntax Bool ::= ciEq(String, String) [function]
  syntax Bool ::= errWord(String) [function]
  syntax Bool ::= nonEmptyCols(Cols) [function]
  syntax String ::= lowerErr(String) [function]

  rule errWord(E:String) => ciEq(E, "serr") orBool ciEq(E, "terr")

  rule nonEmptyCols(.Cols) => false
  rule nonEmptyCols(_:Int _:Cols) => true

  // The repaired source implements this rule with the scoped inline regex flag
  // (?i:READ [TS]ERR), followed by the existing numeric column list grammar.
  rule <k> lineType(readErr(R:String, E:String, CS:Cols)) => command ... </k>
    requires ciEq(R, "read")
     andBool errWord(E)
     andBool nonEmptyCols(CS)

  rule <k> lineType(dataLine(_:Int)) => data ... </k>
  rule <k> lineType(commentLine) => comment ... </k>
  rule <k> lineType(newLine) => new ... </k>
  rule <k> lineType(invalidLine) => error ... </k>

  // Models command[1].lower() in _get_tables_from_qdp_file.
  rule lowerErr(E:String) => "serr" requires ciEq(E, "serr")
  rule lowerErr(E:String) => "terr" requires ciEq(E, "terr")

  rule <k> errKey(readErr(_:String, E:String, _:Cols)) => lowerErr(E) ... </k>
    requires errWord(E)
endmodule

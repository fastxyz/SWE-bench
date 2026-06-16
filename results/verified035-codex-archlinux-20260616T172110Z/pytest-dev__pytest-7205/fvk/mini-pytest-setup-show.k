module MINI-PYTEST-SETUP-SHOW-SYNTAX
  imports STRING-SYNTAX
  imports BOOL-SYNTAX
  imports INT-SYNTAX

  syntax Param ::= strParam(String)
                 | bytesParam(String)
                 | otherParam(String)

  syntax IdValue ::= idStr(String)
                   | idBytes(String)
                   | idOther(String)

  syntax Display ::= display(String)
  syntax Outcome ::= ok(Display) | bytesWarning

  syntax Action ::= rawParam(Param)
                  | fixtureId(IdValue)
                  | writeCached(Display)
                  | oldWriteParam(Param)

  syntax Display ::= safeRepr42(Param) [function]
  syntax Display ::= bracket(Display) [function]
  syntax Int ::= displayLength(Display) [function]
  syntax KResult ::= Display | Outcome
endmodule

module MINI-PYTEST-SETUP-SHOW
  imports MINI-PYTEST-SETUP-SHOW-SYNTAX
  imports STRING
  imports BOOL
  imports INT

  configuration <k> $PGM:Action </k>

  // Raw fixture params are represented, not stringified.
  rule <k> rawParam(P:Param) => safeRepr42(P) </k>

  // Explicit user ids are display labels. Plain string ids keep their label
  // spelling; non-string ids are made safe before being cached.
  rule <k> fixtureId(idStr(S:String)) => display(S) </k>
  rule <k> fixtureId(idBytes(B:String)) => safeRepr42(bytesParam(B)) </k>
  rule <k> fixtureId(idOther(R:String)) => safeRepr42(otherParam(R)) </k>

  // Once cached, the setup-show writer receives a Display string and only adds
  // brackets; it never calls Python str() on the original parameter.
  rule <k> writeCached(D:Display) => ok(bracket(D)) </k>

  // The legacy behavior is modeled only to localize the reported failure.
  rule <k> oldWriteParam(bytesParam(_:String)) => bytesWarning </k>
  rule <k> oldWriteParam(strParam(S:String)) => ok(display("[" +String S +String "]")) </k>
  rule <k> oldWriteParam(otherParam(R:String)) => ok(display("[" +String R +String "]")) </k>

  // Spec axiom for the imported pytest helper. This is the helper contract from
  // _pytest._io.saferepr: total safe representation, bounded by the requested
  // maxsize, and no BytesWarning-producing str(bytes) path.
  rule displayLength(safeRepr42(_:Param)) => 42 [simplification]
  rule bracket(display(S:String)) => display("[" +String S +String "]") [simplification]
endmodule

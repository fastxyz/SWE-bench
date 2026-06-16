module MINI-JSON-FORM-SYNTAX
  imports BOOL-SYNTAX
  imports STRING-SYNTAX

  syntax Encoder ::= "noneEncoder" | "customEncoder" "(" String ")"
  syntax UText ::= "chinaText" | "asciiText" | "otherUnicodeText"
  syntax JVal ::= "invalidInput" "(" String ")"
                | "jstring" "(" UText ")"
                | "jobjectWithText" "(" UText ")"
                | "jarrayWithText" "(" UText ")"
                | "otherJson"

  syntax Display ::= "raw" "(" String ")"
                   | "displayUnicodeChina"
                   | "displayEscapedChina"
                   | "dumped" "(" JVal "," Bool "," Encoder ")"
                   | "jsonDumps" "(" JVal "," Bool "," Encoder ")" [function]

  syntax Exp ::= "prepareValue" "(" JVal "," Encoder ")"
  syntax KResult ::= Display
endmodule

module MINI-JSON-FORM
  imports MINI-JSON-FORM-SYNTAX
  imports BOOL

  configuration <k> $PGM:Exp </k>

  syntax Bool ::= "isInvalid" "(" JVal ")" [function]
  rule isInvalid(invalidInput(_)) => true
  rule isInvalid(jstring(_)) => false
  rule isInvalid(jobjectWithText(_)) => false
  rule isInvalid(jarrayWithText(_)) => false
  rule isInvalid(otherJson) => false

  // InvalidJSONInput is a str subclass in Django and must be redisplayed as-is.
  rule <k> prepareValue(invalidInput(S:String), _E:Encoder) => raw(S) ... </k>

  // This is the V1 normal branch: json.dumps(value, ensure_ascii=False, cls=self.encoder).
  rule <k> prepareValue(V:JVal, E:Encoder) => jsonDumps(V, false, E) ... </k>
    requires notBool isInvalid(V)

  // Concrete discriminator for the public issue example. The pre-fix/default
  // ensure_ascii=True path lands in displayEscapedChina instead.
  rule jsonDumps(jstring(chinaText), false, _E:Encoder) => displayUnicodeChina
  rule jsonDumps(jstring(chinaText), true, _E:Encoder) => displayEscapedChina

  // ASCII text is unaffected by ensure_ascii.
  rule jsonDumps(jstring(asciiText), false, E:Encoder) => dumped(jstring(asciiText), true, E)
  rule jsonDumps(jstring(asciiText), true, E:Encoder) => dumped(jstring(asciiText), true, E)

  rule jsonDumps(V:JVal, B:Bool, E:Encoder) => dumped(V, B, E) [owise]
endmodule

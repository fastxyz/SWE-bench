module MINI-REQUESTS-METHOD-SYNTAX
  imports STRING-SYNTAX
  imports BOOL-SYNTAX

  syntax Token ::= token(String)
  syntax PyVal ::= native(Token) | bytes(Token)
  syntax Text ::= nativeText(Token) | bytesReprText(Token)
  syntax WireMethod ::= prepared(Token) | preparedBytesRepr(Token)

  syntax Cmd ::= sessionRequest(PyVal)
               | legacySessionRequest(PyVal)
               | toNative(PyVal)
               | builtinStr(PyVal)
               | upper(Text)

  syntax KItem ::= upperThenRequest | makeRequest
  syntax KResult ::= Text | WireMethod
endmodule

module MINI-REQUESTS-METHOD
  imports MINI-REQUESTS-METHOD-SYNTAX
  imports STRING
  imports BOOL

  configuration <k> $PGM:Cmd </k>

  syntax Token ::= upperToken(Token) [function]
  syntax Bool ::= asciiHttpToken(Token) [function]

  rule asciiHttpToken(T:Token) => true

  rule <k> sessionRequest(M:PyVal)
        => toNative(M) ~> upperThenRequest
       ...
       </k>

  rule <k> legacySessionRequest(M:PyVal)
        => builtinStr(M) ~> upperThenRequest
       ...
       </k>

  rule <k> toNative(native(T:Token)) => nativeText(T) ... </k>
  rule <k> toNative(bytes(T:Token))  => nativeText(T) ... </k>

  rule <k> builtinStr(native(T:Token)) => nativeText(T) ... </k>
  rule <k> builtinStr(bytes(T:Token))  => bytesReprText(T) ... </k>

  rule <k> TXT:Text ~> upperThenRequest
        => upper(TXT) ~> makeRequest
       ...
       </k>

  rule <k> upper(nativeText(T:Token))    => nativeText(upperToken(T)) ... </k>
  rule <k> upper(bytesReprText(T:Token)) => bytesReprText(upperToken(T)) ... </k>

  rule <k> nativeText(T:Token) ~> makeRequest
        => prepared(T)
       ...
       </k>

  rule <k> bytesReprText(T:Token) ~> makeRequest
        => preparedBytesRepr(T)
       ...
       </k>
endmodule

// Constructed FVK artifact, not machine-checked.
// Mini semantics for the response-body conversion slice audited in
// repo/django/http/response.py. This is an abstract model of the relevant
// Python branch behavior, not a full Python semantics.

module MINI-PYTHON-RESPONSE-SYNTAX
  imports STRING-SYNTAX
  imports BOOL-SYNTAX
  imports LIST-SYNTAX

  syntax Charset ::= charset(String)
  syntax Value ::= bytesValue(String)
                 | textValue(String)
                 | memoryView(String)
                 | otherValue(String)
                 | iterableValue(List)

  syntax Bytes ::= outBytes(String)
                 | encodedText(String, Charset) [function]
                 | encodedOther(String, Charset) [function]
                 | joined(List, Charset) [function]

  syntax Cmd ::= makeBytes(Value, Charset)
               | setContent(Value, Charset)
               | storeContent(Bytes)

  syntax KResult ::= Bytes
endmodule

module MINI-PYTHON-RESPONSE
  imports MINI-PYTHON-RESPONSE-SYNTAX
  imports BOOL
  imports LIST

  configuration
    <k> $PGM:Cmd </k>
    <container> .List </container>

  syntax Bool ::= isScalarContent(Value) [function]
  rule isScalarContent(bytesValue(_)) => true
  rule isScalarContent(textValue(_)) => true
  rule isScalarContent(memoryView(_)) => true
  rule isScalarContent(otherValue(_)) => false
  rule isScalarContent(iterableValue(_)) => false

  // Models HttpResponseBase.make_bytes().
  rule <k> makeBytes(bytesValue(S), _) => outBytes(S) ... </k>
  rule <k> makeBytes(memoryView(S), _) => outBytes(S) ... </k>
  rule <k> makeBytes(textValue(S), C) => encodedText(S, C) ... </k>
  rule <k> makeBytes(otherValue(S), C) => encodedOther(S, C) ... </k>

  // Models HttpResponse.content assignment for scalar values.
  rule <k> setContent(V, C) => makeBytes(V, C) ~> storeContent ... </k>
    requires isScalarContent(V)
  rule <k> B:Bytes ~> storeContent => .K ... </k>
       <container> _ => ListItem(B) </container>

  // Models the existing iterable-chunk path.
  rule <k> setContent(iterableValue(CHUNKS), C) => .K ... </k>
       <container> _ => ListItem(joined(CHUNKS, C)) </container>
endmodule

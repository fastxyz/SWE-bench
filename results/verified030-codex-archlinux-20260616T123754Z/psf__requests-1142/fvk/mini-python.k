requires "domains.md"

module MINI-REQUESTS-SYNTAX
  imports INT
  imports BOOL

  syntax Method ::= "GET" | "OTHER"
  syntax Data ::= omitted | noneData | emptyDict | bodyData(Int) | streamData(Int)
  syntax Body ::= noBody | body(Int) | streamBody(Int)
  syntax Headers ::= headers(Bool)
  syntax Result ::= result(Body, Headers)

  syntax Exp ::= normalizeData(Data) [function]
               | bodyFromData(Data) [function]
               | prepareContentLength(Method, Body, Headers) [function]
               | prepareBody(Method, Data, Headers) [function]
endmodule

module MINI-REQUESTS
  imports MINI-REQUESTS-SYNTAX
  imports INT
  imports BOOL

  configuration <k> $PGM:Exp </k>

  // Request.__init__: omitted data and explicit None are no-body values.
  rule normalizeData(omitted) => emptyDict
  rule normalizeData(noneData) => emptyDict
  rule normalizeData(D:Data) => D [owise]

  // prepare_body abstraction: only the body/no-body distinction is modeled.
  rule bodyFromData(emptyDict) => noBody
  rule bodyFromData(bodyData(N)) => body(N) requires N >=Int 0
  rule bodyFromData(streamData(N)) => streamBody(N) requires N >=Int 0

  // prepare_content_length abstraction.
  rule prepareContentLength(GET, noBody, headers(false)) => headers(false)
  rule prepareContentLength(GET, noBody, headers(true)) => headers(true)
  rule prepareContentLength(OTHER, noBody, headers(false)) => headers(true)
  rule prepareContentLength(OTHER, noBody, headers(true)) => headers(true)
  rule prepareContentLength(M:Method, body(N), H:Headers) => headers(true)
    requires N >=Int 0
  rule prepareContentLength(M:Method, streamBody(N), H:Headers) => headers(true)
    requires N >=Int 0

  rule prepareBody(M:Method, D:Data, H:Headers)
    => result(bodyFromData(normalizeData(D)),
              prepareContentLength(M, bodyFromData(normalizeData(D)), H))
endmodule

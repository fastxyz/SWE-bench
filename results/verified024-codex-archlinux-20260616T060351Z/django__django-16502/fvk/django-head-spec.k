requires "mini-wsgi-head.k"

module DJANGO-HEAD-SPEC
  imports MINI-WSGI-HEAD

  // SPEC-PROVENANCE:
  // - from_prompt: "response bodies must not be returned for HEAD requests"
  //   => body-output bytes must be unchanged on the ServerHandler HEAD path.
  // - from_prompt: "letting the server perform the body removal"
  //   => response objects are not mutated before the server layer.
  // - from_hint: "body won't be empty as far as middleware is concerned"
  //   => middleware may compute validators before final server stripping.
  // - from_code: ServerHandler.write(), sendfile(), finish_response() are the
  //   output-producing hooks that V2 overrides.
  claim <k> write(bytes(N)) => . ... </k>
        <method> HEAD </method>
        <status> true </status>
        <headersSent> HS:Bool </headersSent>
        <stdoutBytes> OUT:Int => OUT:Int </stdoutBytes>
        <flushed> _ => true </flushed>
    requires N >=Int 0

  // SPEC-PROVENANCE:
  // - from_prompt: compliant user agents may terminate after headers.
  // - from_code: sendfile is a possible alternate body-producing path.
  claim <k> sendfile => . ... </k>
        <method> HEAD </method>
        <sendfileUsed> _ => false </sendfileUsed>
        <stdoutBytes> OUT:Int => OUT:Int </stdoutBytes>

  // SPEC-PROVENANCE:
  // - from_prompt: no HEAD body returned by runserver.
  // - from_code: finish_response controls response iteration and closing.
  // - from_proof_finding: abnormal exits must still close the response object.
  claim <k> finishHead => . ... </k>
        <method> HEAD </method>
        <result> RESULT:Chunks => _ </result>
        <stdoutBytes> OUT:Int => OUT:Int </stdoutBytes>
        <flushed> _ => true </flushed>
        <closed> _ => true </closed>
        <resultClosed> _ => true </resultClosed>

  // SPEC-PROVENANCE:
  // - from_hint: entity tag validators can still be set for HEAD.
  // - from_code: ConditionalGetMiddleware gates on request.method.
  // This is modeled as an adequacy obligation rather than an executable rule:
  // method in {GET, HEAD} reaches conditional processing; other methods return
  // the original response unchanged.
endmodule

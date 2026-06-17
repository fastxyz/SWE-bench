requires "domains.md"

module MINI-JS-FORMDATA-SYNTAX
  imports INT
  imports STRING

  syntax Data ::= LegacyFormData(Int)
                | SpecFormData(Int)
                | StreamData
                | BufferData
                | StringData
                | OtherObject

  syntax Headers ::= headers(String, Int)
  syntax Result ::= ok(Data, Headers)
                  | rejected(String)

  syntax Action ::= adapter(Data, Headers)
                  | formDataToStream(Data, Headers)

  syntax Int ::= multipartLength(Int) [function]
  syntax String ::= multipartContentType [function]
endmodule

module MINI-JS-FORMDATA
  imports MINI-JS-FORMDATA-SYNTAX
  imports INT
  imports STRING

  configuration <k> $PGM:Action </k>

  rule multipartLength(N:Int) => N requires N >=Int 0
  rule multipartContentType => "multipart/form-data; boundary=<generated>"

  // Existing form-data package path: getHeaders() wins before any spec-form branch.
  rule <k> adapter(LegacyFormData(L), headers(_, _))
        => ok(LegacyFormData(L), headers("legacy-form-data-headers", L)) ... </k>
    requires L >=Int 0

  // Node 18 / WHATWG FormData path added by the fix.
  rule <k> adapter(SpecFormData(N), H:Headers)
        => formDataToStream(SpecFormData(N), H) ... </k>
    requires N >=Int 0

  rule <k> formDataToStream(SpecFormData(N), headers(_, _))
        => ok(StreamData, headers(multipartContentType, multipartLength(N))) ... </k>
    requires N >=Int 0

  // Pre-existing supported non-FormData request bodies remain accepted.
  rule <k> adapter(StreamData, H:Headers) => ok(StreamData, H) ... </k>
  rule <k> adapter(BufferData, H:Headers) => ok(BufferData, H) ... </k>
  rule <k> adapter(StringData, H:Headers) => ok(BufferData, H) ... </k>

  // Unsupported objects still reject with the public adapter error.
  rule <k> adapter(OtherObject, H:Headers)
        => rejected("Data after transformation must be a string, an ArrayBuffer, a Buffer, or a Stream") ... </k>
endmodule

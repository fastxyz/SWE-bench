requires "mini-js-http-encoding.k"

module HTTP-ENCODING-SPEC
  imports MINI-JS-HTTP-ENCODING
  imports BOOL
  imports INT
  imports STRING

  // SPEC-PROVENANCE:
  // - from_prompt: non-lowercase content-encoding values such as GZIP must decode.
  // - from_code: gzip/compress aliases share the existing unzip branch.
  claim <k> decide(true, otherMethod, STATUS:Int, present(E:String), BR:Bool) => unzipAndDropEncoding </k>
    requires STATUS =/=Int 204
     andBool (norm(E) ==String "gzip"
       orBool norm(E) ==String "x-gzip"
       orBool norm(E) ==String "compress"
       orBool norm(E) ==String "x-compress")
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: comparison is case-insensitive for all supported values.
  // - from_code: deflate uses header transform plus unzip.
  claim <k> decide(true, otherMethod, STATUS:Int, present(E:String), BR:Bool) => deflateAndDropEncoding </k>
    requires STATUS =/=Int 204
     andBool norm(E) ==String "deflate"
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: comparison is case-insensitive for all supported values.
  // - from_code: Brotli decoding is guarded by isBrotliSupported.
  claim <k> decide(true, otherMethod, STATUS:Int, present(E:String), true) => brotliAndDropEncoding </k>
    requires STATUS =/=Int 204
     andBool norm(E) ==String "br"
    [all-path]

  // SPEC-PROVENANCE:
  // - from_code: unsupported Brotli keeps existing pass-through behavior.
  claim <k> decide(true, otherMethod, STATUS:Int, present(E:String), false) => passThrough </k>
    requires STATUS =/=Int 204
     andBool norm(E) ==String "br"
    [all-path]

  // SPEC-PROVENANCE:
  // - from_code/comment: if decompress disabled we should not decompress.
  claim <k> decide(false, M:Method, STATUS:Int, H:Header, BR:Bool) => passThrough </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_code: no content-encoding header means no decoder path.
  claim <k> decide(true, M:Method, STATUS:Int, absent, BR:Bool) => passThrough </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_code/comment: HEAD has no body; remove header but add no decoder.
  claim <k> decide(true, headMethod, STATUS:Int, present(E:String), BR:Bool) => dropEncodingOnly </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_code/comment: 204 has no body; remove header but add no decoder.
  claim <k> decide(true, otherMethod, 204, present(E:String), BR:Bool) => dropEncodingOnly </k>
    [all-path]
endmodule

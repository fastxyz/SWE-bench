requires "mini-requests-body.k"

module REQUESTS-BODY-SPEC
  imports MINI-REQUESTS-BODY

  // SPEC-PROVENANCE:
  // - from_prompt: binary data payload must not fail through to_native_string.
  // - from_code: V2 _encode_params has a bytes branch before the text branch.
  claim
    <k> encodeParams(rawBytes(B:Bytes)) => B ... </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: data=u"...".encode("utf-8") is a valid raw body.
  // - from_docs: data is the body to attach to the request.
  // - from_code: prepare_body calls _encode_params for truthy non-file data.
  claim
    <k> prepareBody(rawBytes(B:Bytes), noFiles())
      => prepared(bodyBytes(B), noCType(), len(B)) ... </k>
    requires nonEmpty(B)
    [all-path]

  // SPEC-PROVENANCE:
  // - from_public_test: params=b"test=foo" prepares ?test=foo.
  // - from_code: prepare_url converts byte enc_params at URL assembly time.
  claim
    <k> prepareUrlParams(rawBytes(Q:Bytes), noQuery())
      => urlPrepared(query(toNative(Q))) ... </k>
    requires asciiBytes(Q)
    [all-path]

  // SPEC-PROVENANCE:
  // - from_docs: dictionaries are form-encoded.
  // - from_public_test: data={"life": "42"} prepares body life=42.
  // - from_code: iterable non-string branch remains unchanged.
  claim
    <k> prepareBody(formData(F:String), noFiles())
      => prepared(bodyForm(urlEncode(F)), formCType(), lenNative(urlEncode(F))) ... </k>
    [all-path]
endmodule

// Constructed FVK artifact, not machine-checked.

requires "mini-python-response.k"

module HTTP-RESPONSE-SPEC
  imports MINI-PYTHON-RESPONSE
  imports LIST

  // SPEC-PROVENANCE:
  // - from_prompt: "make_bytes could be adapted to deal with memoryview objects by casting them to bytes"
  //   => make_bytes(memoryview(payload)) returns bytes(payload).
  // - from_prompt: "simply wrapping the memoryview in bytes works as a workaround"
  //   => bytes(memoryview) is the intended conversion.
  claim
    <k> makeBytes(memoryView(PAYLOAD:String), C:Charset) => outBytes(PAYLOAD) </k>
    <container> .List </container>
    [all-path, label(MAKE-BYTES-MEMORYVIEW)]

  // SPEC-PROVENANCE:
  // - from_prompt: "HttpResponse(memoryview(b\"My Content\")) ... expecting b'My Content'"
  //   => regular HttpResponse content from a memoryview is the underlying bytes.
  // - from_code: content assignment consumes ordinary iterables, but memoryview is a scalar
  //   bytes-like value for this contract.
  claim
    <k> setContent(memoryView(PAYLOAD:String), C:Charset) => .K </k>
    <container> .List => ListItem(outBytes(PAYLOAD)) </container>
    [all-path, label(CONTENT-MEMORYVIEW)]

  // SPEC-PROVENANCE:
  // - from_prompt: bytes content example is marked correct.
  //   => bytes content remains unchanged.
  claim
    <k> setContent(bytesValue(PAYLOAD:String), C:Charset) => .K </k>
    <container> .List => ListItem(outBytes(PAYLOAD)) </container>
    [all-path, label(CONTENT-BYTES-FRAME)]

  // SPEC-PROVENANCE:
  // - from_prompt: string content example is marked correct.
  //   => text content remains charset encoded.
  claim
    <k> setContent(textValue(PAYLOAD:String), C:Charset) => .K </k>
    <container> .List => ListItem(encodedText(PAYLOAD, C)) </container>
    [all-path, label(CONTENT-STRING-FRAME)]

  // SPEC-PROVENANCE:
  // - from_code: "Consume iterators upon assignment to allow repeated iteration."
  //   => non-scalar iterables are still consumed as chunks.
  claim
    <k> setContent(iterableValue(CHUNKS:List), C:Charset) => .K </k>
    <container> .List => ListItem(joined(CHUNKS, C)) </container>
    [all-path, label(CONTENT-ITERABLE-FRAME)]
endmodule

requires "mini-mime.k"

module FILERESPONSE-CONTENT-TYPE-SPEC
  imports MINI-MIME

  // SPEC-PROVENANCE:
  // - from_prompt: "Improper guessing of Mime Type for \"br\" ... FileResponse(open('test.html.br', 'rb'))"
  //   => .br is an in-domain compressed suffix and must not produce text/html.
  // - from_public_test: existing compressed FileResponse cases map to compressed-file media types.
  claim [BR-FILERESPONSE]:
    <k> effectiveContentType(noExplicit, file(htmlBr), guess(some(textHtml), br)) => appXBrotli </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: "Improper guessing of Mime Type for ... \"Z\" file types ... FileResponse(open('test.html.Z', 'rb'))"
  //   => .Z is an in-domain compressed suffix and must not produce text/html.
  // - from_public_test: existing compressed FileResponse cases map to compressed-file media types.
  claim [COMPRESS-FILERESPONSE]:
    <k> effectiveContentType(noExplicit, file(htmlZ), guess(some(textHtml), compress)) => appXCompress </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_public_test: .tar.gz maps to application/gzip.
  claim [GZIP-PRESERVED]:
    <k> effectiveContentType(noExplicit, file(tarGz), guess(noType, gzip)) => appGzip </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_public_test: .tar.bz2 maps to application/x-bzip.
  claim [BZIP2-PRESERVED]:
    <k> effectiveContentType(noExplicit, file(tarBz2), guess(noType, bzip2)) => appXBzip </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_public_test: .tar.xz maps to application/x-xz.
  claim [XZ-PRESERVED]:
    <k> effectiveContentType(noExplicit, file(tarXz), guess(noType, xz)) => appXXz </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_code: explicit content_type is a public frame condition.
  claim [EXPLICIT-CONTENT-TYPE]:
    <k> effectiveContentType(explicit(videoWebm), file(anyFile), guess(some(textHtml), br)) => videoWebm </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_code: no filename falls back to application/octet-stream.
  claim [NO-FILENAME-FALLBACK]:
    <k> effectiveContentType(noExplicit, noFile, noGuess) => appOctet </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_code: unknown guessed content type falls back to application/octet-stream.
  claim [UNKNOWN-FALLBACK]:
    <k> effectiveContentType(noExplicit, file(unknownFile), guess(noType, noEncoding)) => appOctet </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_public_test: FileResponse compressed responses do not set Content-Encoding.
  // - from_code_comment: "Encoding isn't set to prevent browsers from automatically uncompressing files."
  claim [NO-CONTENT-ENCODING]:
    <k> fileResponseSetsContentEncoding(noExplicit, guess(some(textHtml), br)) => noContentEncoding </k>
    [all-path]
endmodule

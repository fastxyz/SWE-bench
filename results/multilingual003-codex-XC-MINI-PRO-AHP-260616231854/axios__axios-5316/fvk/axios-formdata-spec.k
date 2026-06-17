requires "mini-js-formdata.k"

module AXIOS-FORMDATA-SPEC
  imports MINI-JS-FORMDATA
  imports INT
  imports STRING

  // SPEC-PROVENANCE:
  // - from_prompt: "Using FormData type from Node.js 18 global leads to an error" =>
  //   spec-compliant Node FormData is in-domain request data.
  // - from_prompt: "Expected behavior: Support of Node.js FormData added to Axios" =>
  //   the adapter must not reject this data with the unsupported object error.
  // - from_code: V2 branch converts SpecFormData to a stream and sets multipart headers.
  claim <k> adapter(SpecFormData(N), headers("multipart/form-data", 0))
        => ok(StreamData, headers("multipart/form-data; boundary=<generated>", N)) ... </k>
    requires N >=Int 0
    [all-path]

  // SPEC-PROVENANCE:
  // - from_code: the existing form-data package branch was already supported.
  // - from_public_compatibility: the fix must preserve legacy form-data behavior.
  claim <k> adapter(LegacyFormData(L), headers("multipart/form-data", 0))
        => ok(LegacyFormData(L), headers("legacy-form-data-headers", L)) ... </k>
    requires L >=Int 0
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: the reported error is wrong for Node 18 FormData.
  // - from_code: unrelated unsupported objects still use the same error path.
  claim <k> adapter(OtherObject, headers("", 0))
        => rejected("Data after transformation must be a string, an ArrayBuffer, a Buffer, or a Stream") ... </k>
    [all-path]
endmodule

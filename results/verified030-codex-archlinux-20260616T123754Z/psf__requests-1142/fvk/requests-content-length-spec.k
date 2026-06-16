requires "mini-python.k"

module REQUESTS-CONTENT-LENGTH-SPEC
  imports MINI-REQUESTS
  imports INT
  imports BOOL

  // SPEC-PROVENANCE:
  // - E1/E2/E4: bodyless/default GET must not get automatic Content-Length.
  claim <k> prepareBody(GET, omitted, headers(false))
        => result(noBody, headers(false)) </k>
    [all-path, label(GET_NO_BODY)]

  // SPEC-PROVENANCE:
  // - E5/E6/F1: explicit data=None is a public no-body spelling.
  claim <k> prepareBody(GET, noneData, headers(false))
        => result(noBody, headers(false)) </k>
    [all-path, label(GET_NONE_DATA)]

  // SPEC-PROVENANCE:
  // - E3: GET with data is allowed and keeps computed length.
  claim <k> prepareBody(GET, bodyData(N), headers(false))
        => result(body(N), headers(true)) </k>
    requires N >=Int 0
    [all-path, label(GET_BODY)]

  // SPEC-PROVENANCE:
  // - E8: non-GET zero-length behavior remains unchanged.
  claim <k> prepareBody(OTHER, omitted, headers(false))
        => result(noBody, headers(true)) </k>
    [all-path, label(OTHER_NO_BODY)]

  // SPEC-PROVENANCE:
  // - E2: the bug is automatic addition, not user-supplied headers.
  claim <k> prepareBody(GET, omitted, headers(true))
        => result(noBody, headers(true)) </k>
    [all-path, label(GET_EXPLICIT_CL)]
endmodule

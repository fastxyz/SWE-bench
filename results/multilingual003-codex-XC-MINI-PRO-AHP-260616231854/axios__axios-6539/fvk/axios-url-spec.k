requires "mini-js-url.k"

module AXIOS-URL-SPEC
  imports MINI-JS-URL

  // SPEC-PROVENANCE:
  // - from_problem: "protocol-relative URLs are not relevant server-side ... expected result would be an error"
  // - from_code: the HTTP adapter must decide before `new URL(fullPath, "http://localhost")`
  // - from_finding: F-001 requires paired slash/backslash authority forms, after leading C0/space trimming
  claim <k> prepare(slash slash U:URL) => rejectInvalid </k> [all-path]

  // SPEC-PROVENANCE: same as above, with URL-parser-compatible slash/backslash authority spelling.
  claim <k> prepare(slash backslash U:URL) => rejectInvalid </k> [all-path]

  // SPEC-PROVENANCE: same as above, with URL-parser-compatible slash/backslash authority spelling.
  claim <k> prepare(backslash slash U:URL) => rejectInvalid </k> [all-path]

  // SPEC-PROVENANCE: same as above, with URL-parser-compatible slash/backslash authority spelling.
  claim <k> prepare(backslash backslash U:URL) => rejectInvalid </k> [all-path]

  // SPEC-PROVENANCE:
  // - from_problem: the fallback base was introduced for ordinary relative paths
  // - from_code: non-protocol-relative full paths should continue to URL parsing
  claim <k> prepare(other U:URL) => parseWithFallback </k> [all-path]

  // SPEC-PROVENANCE:
  // - from_problem: only protocol-relative authority targets are rejected
  // - from_code: a single path separator followed by a non-separator remains an ordinary relative path
  claim <k> prepare(slash other U:URL) => parseWithFallback </k> [all-path]

  // SPEC-PROVENANCE:
  // - from_problem: leading parser-trimmed control/space characters must not bypass the server-side rejection
  claim <k> prepare(c0 slash slash U:URL) => rejectInvalid </k> [all-path]
endmodule


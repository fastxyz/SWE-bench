requires "mini-linkcheck.k"

module LINKCHECK-SPEC
  imports MINI-LINKCHECK
  imports BOOL
  imports INT

  // SPEC-PROVENANCE:
  // - from_prompt: "fallback to GET requests when HEAD requests returns Too Many Redirects"
  //   => a HEAD TooManyRedirects outcome must use the same GET classification path
  //      as the existing HEAD HTTPError fallback.
  // - from_prompt: "the GET fallback is ignored as the exception is of type
  //   TooManyRedirects and the link is reported as broken"
  //   => returning broken before GET is the legacy bug, not an allowed outcome.
  // - from_code: the non-anchor branch tries HEAD, catches fallback exceptions,
  //   then calls GET and classifies the GET response/error.
  claim
    <k> checkNoAnchor(tooManyRedirects, ok(true, C:Int)) => result(working, true) </k>
    [all-path]

  claim
    <k> checkNoAnchor(tooManyRedirects, ok(false, C:Int)) => result(redirected(C), true) </k>
    [all-path]

  claim
    <k> checkNoAnchor(tooManyRedirects, httpError(401)) => result(workingUnauthorized, true) </k>
    [all-path]

  claim
    <k> checkNoAnchor(tooManyRedirects, httpError(503)) => result(ignored503, true) </k>
    [all-path]

  claim
    <k> checkNoAnchor(tooManyRedirects, httpError(S:Int)) => result(broken, true) </k>
    requires S =/=Int 401 andBool S =/=Int 503
    [all-path]

  claim
    <k> checkNoAnchor(tooManyRedirects, tooManyRedirects) => result(broken, true) </k>
    [all-path]

  claim
    <k> checkNoAnchor(tooManyRedirects, otherError) => result(broken, true) </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_public_test: test_follows_redirects_on_HEAD expects HEAD 302->204 to
  //   be classified as redirected, with no GET log entry.
  // - frame condition: V1 must not change successful HEAD behavior.
  claim
    <k> checkNoAnchor(ok(true, C:Int), G:Outcome) => result(working, false) </k>
    [all-path]

  claim
    <k> checkNoAnchor(ok(false, C:Int), G:Outcome) => result(redirected(C), false) </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_public_test: test_follows_redirects_on_GET expects HEAD 405 to be
  //   followed by GET, and the GET redirect classification to be reported.
  // - frame condition: V1 must preserve the existing HTTPError fallback.
  claim
    <k> checkNoAnchor(httpError(S:Int), ok(false, C:Int)) => result(redirected(C), true) </k>
    [all-path]
endmodule

requires "mini-python.k"

module LINKCHECK-SPEC
  imports MINI-PYTHON

  // SPEC-PROVENANCE:
  // - from_prompt: "Linkcheck should report HTTP errors instead of Anchor not found"
  //   => ordinary HTTP errors are classified before anchor parsing.
  // - from_prompt: "e.g. 404, 500" => statusHttpError covers non-special HTTP errors.
  // - from_code: V1 calls response.raise_for_status() before check_anchor().
  claim
    <k> checkAnchorBranch(statusHttpError, A:AnchorState, R:RedirectState)
      => resultBrokenHttp ... </k>
    <anchorChecks> 0 => 0 </anchorChecks>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: "Same as when linkcheck_anchors=False"
  //   => preserve the existing HTTPError policy.
  // - from_code: existing HTTPError handler treats 401 as working.
  claim
    <k> checkAnchorBranch(statusUnauthorized, A:AnchorState, R:RedirectState)
      => resultWorkingUnauthorized ... </k>
    <anchorChecks> 0 => 0 </anchorChecks>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: "Same as when linkcheck_anchors=False"
  //   => preserve the existing HTTPError policy.
  // - from_code: existing HTTPError handler treats 503 as ignored.
  claim
    <k> checkAnchorBranch(statusUnavailable, A:AnchorState, R:RedirectState)
      => resultIgnoredHttp ... </k>
    <anchorChecks> 0 => 0 </anchorChecks>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_docs: "If true, check the validity of #anchors in links"
  //   => successful responses still run anchor validation.
  // - from_public_tests: successful pages without anchors report Anchor not found.
  claim
    <k> checkAnchorBranch(statusOK, anchorMissing, R:RedirectState)
      => resultBrokenAnchor ... </k>
    <anchorChecks> 0 => 1 </anchorChecks>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_docs: successful responses with valid anchors remain working.
  claim
    <k> checkAnchorBranch(statusOK, anchorFound, sameUrl)
      => resultWorking ... </k>
    <anchorChecks> 0 => 1 </anchorChecks>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_docs: successful responses with valid anchors remain checked.
  // - from_code: existing redirect branch appends the original anchor.
  claim
    <k> checkAnchorBranch(statusOK, anchorFound, redirectedUrl)
      => resultRedirected ... </k>
    <anchorChecks> 0 => 1 </anchorChecks>
    [all-path]
endmodule

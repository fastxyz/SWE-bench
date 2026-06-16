requires "mini-requests-proxy.k"

module REQUESTS-PROXY-SPEC
  imports MINI-REQUESTS-PROXY

  // SPEC-PROVENANCE:
  // - from_prompt: benchmark/PROBLEM.md lines 100-113 say auth is parsed but
  //   lost from netloc during prepend_scheme_if_needed.
  // - from_docs: repo/docs/user/advanced.rst lines 620-626 document
  //   http://user:password@host/ proxy auth syntax.
  // - from_code: repo/requests/utils.py lines 973-985 rebuild the URL from
  //   parsed components.
  // AUTH-PRESERVE-EXISTING-SCHEME
  claim
    <k>
      prependScheme(purl(SCHEME, AUTH, NETLOC, PATH, QUERY, FRAG), NEW)
      =>
      out(SCHEME, AUTH +String "@" +String NETLOC, PATH, QUERY, FRAG)
    </k>
    requires SCHEME =/=String ""
     andBool AUTH =/=String ""
     andBool NETLOC =/=String ""
    [all-path]

  // AUTH-PRESERVE-PREPENDED-SCHEME
  claim
    <k>
      prependScheme(purl("", AUTH, NETLOC, PATH, QUERY, FRAG), NEW)
      =>
      out(NEW, AUTH +String "@" +String NETLOC, PATH, QUERY, FRAG)
    </k>
    requires AUTH =/=String ""
     andBool NETLOC =/=String ""
    [all-path]

  // NO-AUTH-FRAME
  claim
    <k>
      prependScheme(purl(SCHEME, "", NETLOC, PATH, QUERY, FRAG), NEW)
      =>
      out(effectiveScheme(SCHEME, NEW), NETLOC, PATH, QUERY, FRAG)
    </k>
    requires NETLOC =/=String ""
    [all-path]

  // PATH-SWAP-FRAME
  claim
    <k>
      prependScheme(purl(SCHEME, AUTH, "", PATH, QUERY, FRAG), NEW)
      =>
      out(effectiveScheme(SCHEME, NEW), withAuth(AUTH, PATH), "", QUERY, FRAG)
    </k>
    [all-path]
endmodule

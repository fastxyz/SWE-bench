requires "mini-django-admin.k"

module ADMIN-CATCH-ALL-SPEC
  imports MINI-DJANGO-ADMIN
  imports BOOL
  imports STRING

  // SPEC-PROVENANCE:
  // - from_prompt: "AdminSite.catch_all_view() drops query string in redirects"
  //   => eligible redirects preserve QUERY.
  // - from_prompt: expected "/admin/auth/foo/?id=123"
  //   => slash is in the path component before the query string.
  // - from_code: branch gates are APPEND_SLASH, URL suffix, resolver success,
  //   and should_append_slash.
  claim [CATCH-REDIRECT-PRESERVES-QUERY]:
    <k> CatchAll(true, false, true, true, PATH:String, QUERY:String)
      => Redirect(fullPathSlash(PATH, QUERY)) ... </k>
    requires notBool endsWithSlash(PATH)
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: provided URL includes "?id=123" and expected redirect keeps it.
  // - from_code: _get_full_path appends "?" + iri_to_uri(QUERY_STRING) when non-empty.
  claim [FULL-PATH-NONEMPTY-QUERY]:
    <k> GetFullPathSlash(PATH:String, QUERY:String)
      => slashPath(PATH) +String "?" +String encodedQuery(QUERY) ... </k>
    requires QUERY =/=String ""
    [all-path]

  // SPEC-PROVENANCE:
  // - from_code: _get_full_path omits the query separator when QUERY_STRING is empty.
  claim [FULL-PATH-EMPTY-QUERY]:
    <k> GetFullPathSlash(PATH:String, "")
      => slashPath(PATH) ... </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_code: all failed gates fall through to "raise Http404".
  // - from_prompt: issue concerns only redirects with APPEND_SLASH eligibility.
  claim [CATCH-NO-REDIRECT-WHEN-GATES-FAIL-APPEND-FALSE]:
    <k> CatchAll(false, URLENDS:Bool, RESOLVES:Bool, SHOULD:Bool, PATH:String, QUERY:String)
      => Http404 ... </k>
    [all-path]

  claim [CATCH-NO-REDIRECT-WHEN-GATES-FAIL-URL-ENDS]:
    <k> CatchAll(true, true, RESOLVES:Bool, SHOULD:Bool, PATH:String, QUERY:String)
      => Http404 ... </k>
    [all-path]

  claim [CATCH-NO-REDIRECT-WHEN-GATES-FAIL-NO-RESOLVE]:
    <k> CatchAll(true, false, false, SHOULD:Bool, PATH:String, QUERY:String)
      => Http404 ... </k>
    [all-path]

  claim [CATCH-NO-REDIRECT-WHEN-GATES-FAIL-SHOULD-FALSE]:
    <k> CatchAll(true, false, true, false, PATH:String, QUERY:String)
      => Http404 ... </k>
    [all-path]
endmodule

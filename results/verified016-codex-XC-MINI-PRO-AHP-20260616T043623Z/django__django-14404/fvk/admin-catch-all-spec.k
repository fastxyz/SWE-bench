requires "mini-django-admin-redirect.k"

module ADMIN-CATCH-ALL-SPEC
  imports MINI-DJANGO-ADMIN-REDIRECT
  imports STRING
  imports BOOL

  // CLAIM-REDIRECT
  // SPEC-PROVENANCE:
  // - from_prompt: "instead of '%s/' % request.path (with the script name)"
  //   => successful append-slash redirects use PATH + "/".
  // - from_code: resolve() has already been represented by RESOLVE, the result
  //   of resolving PATHINFO + "/"; PATHINFO is not the redirect target.
  claim
    <k> catchAll(true, false, PATHINFO:String, PATH:String, resolved(true))
      => redirect(PATH +String "/") </k>
    [all-path]

  // CLAIM-FORCE-SCRIPT-NAME-WITNESS
  // SPEC-PROVENANCE:
  // - from_prompt: "catch_all_view() does not support FORCE_SCRIPT_NAME"
  //   => a script-prefixed request redirects to the script-prefixed PATH.
  claim
    <k> catchAll(true, false, "/admin/auth/user", "/script/admin/auth/user", resolved(true))
      => redirect("/script/admin/auth/user/") </k>
    [all-path]

  // CLAIM-NO-REDIRECT-APPEND-FALSE
  claim
    <k> catchAll(false, URLENDS:Bool, PATHINFO:String, PATH:String, RESULT:ResolveResult)
      => http404 </k>
    [all-path]

  // CLAIM-NO-REDIRECT-URL-SLASH
  claim
    <k> catchAll(true, true, PATHINFO:String, PATH:String, RESULT:ResolveResult)
      => http404 </k>
    [all-path]

  // CLAIM-NO-REDIRECT-RESOLVER404
  claim
    <k> catchAll(true, false, PATHINFO:String, PATH:String, resolver404)
      => http404 </k>
    [all-path]

  // CLAIM-NO-REDIRECT-SHOULD-NOT-APPEND
  claim
    <k> catchAll(true, false, PATHINFO:String, PATH:String, resolved(false))
      => http404 </k>
    [all-path]
endmodule

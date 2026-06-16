module MINI-DJANGO-ADMIN-REDIRECT-SYNTAX
  imports BOOL-SYNTAX
  imports STRING-SYNTAX

  syntax ResolveResult ::= "resolver404"
                         | "resolved" "(" Bool ")"

  syntax Outcome ::= "redirect" "(" String ")"
                   | "http404"

  syntax Action ::= "catchAll" "(" Bool "," Bool "," String "," String "," ResolveResult ")"
  syntax KResult ::= Outcome
endmodule

module MINI-DJANGO-ADMIN-REDIRECT
  imports MINI-DJANGO-ADMIN-REDIRECT-SYNTAX
  imports BOOL
  imports STRING

  configuration <k> $PGM:Action </k>

  // R-REDIRECT: models the branch:
  // APPEND_SLASH && !url.endswith("/") && resolve(PATHINFO + "/") succeeds
  // with should_append_slash true. The redirect target is PATH + "/".
  rule <k> catchAll(true, false, PATHINFO:String, PATH:String, resolved(true))
        => redirect(PATH +String "/") </k>

  // R-NO-APPEND: settings.APPEND_SLASH is false.
  rule <k> catchAll(false, URLENDS:Bool, PATHINFO:String, PATH:String, RESULT:ResolveResult)
        => http404 </k>

  // R-URL-SLASH: the captured admin catch-all URL already ends with "/".
  rule <k> catchAll(true, true, PATHINFO:String, PATH:String, RESULT:ResolveResult)
        => http404 </k>

  // R-RESOLVER404: resolve(PATHINFO + "/") raises Resolver404.
  rule <k> catchAll(true, false, PATHINFO:String, PATH:String, resolver404)
        => http404 </k>

  // R-SHOULD-NOT-APPEND: resolved view opts out of append-slash.
  rule <k> catchAll(true, false, PATHINFO:String, PATH:String, resolved(false))
        => http404 </k>
endmodule

module MINI-DJANGO-ADMIN-URL-SYNTAX
  imports STRING-SYNTAX
  imports MAP-SYNTAX

  syntax RouteResult ::= url(String) | noReverseMatch
  syntax Rendered ::= anchor(String, String) | text(String)

  syntax String ::= routeKey(String, String, String) [function]
  syntax KItem ::= getAdminUrl(String, String, String, String, String, Map)
                 | legacyGetAdminUrl(String, String, String, String, String, String, Map)
                 | reverseWithCurrentApp(String, String, String, String, Map)
                 | renderRemoteObject(String)
endmodule

module MINI-DJANGO-ADMIN-URL
  imports MINI-DJANGO-ADMIN-URL-SYNTAX
  imports STRING
  imports MAP
  imports K-EQUAL

  configuration <k> $PGM:K </k>

  rule routeKey(SITE:String, APP:String, MODEL:String)
    => SITE +String ":" +String APP +String "_" +String MODEL +String "_change"

  // Model of django.urls.reverse("admin:app_model_change", current_app=SITE).
  // The route map stores the path prefix owned by each AdminSite instance.
  rule <k> reverseWithCurrentApp(SITE:String, APP:String, MODEL:String, PK:String, ROUTES:Map)
        => url(ROUTES [ routeKey(SITE, APP, MODEL) ] +String PK +String "/change/") ... </k>
    requires routeKey(SITE, APP, MODEL) in_keys(ROUTES)

  rule <k> reverseWithCurrentApp(SITE:String, APP:String, MODEL:String, PK:String, ROUTES:Map)
        => noReverseMatch ... </k>
    requires notBool routeKey(SITE, APP, MODEL) in_keys(ROUTES)

  // V1 behavior: carry the owning ModelAdmin's AdminSite name into reverse().
  rule <k> getAdminUrl(SITE:String, APP:String, MODEL:String, PK:String, OBJ:String, ROUTES:Map)
        => reverseWithCurrentApp(SITE, APP, MODEL, PK, ROUTES) ~> renderRemoteObject(OBJ) ... </k>

  rule <k> url(URL:String) ~> renderRemoteObject(OBJ:String)
        => anchor(URL, OBJ) ... </k>

  rule <k> noReverseMatch ~> renderRemoteObject(OBJ:String)
        => text(OBJ) ... </k>

  // Pre-fix behavior for the counterexample in FINDINGS.md: the active site
  // is available but ignored, so resolution uses the default instance.
  rule <k> legacyGetAdminUrl(DEFAULT:String, _ACTIVE:String, APP:String, MODEL:String, PK:String, OBJ:String, ROUTES:Map)
        => reverseWithCurrentApp(DEFAULT, APP, MODEL, PK, ROUTES) ~> renderRemoteObject(OBJ) ... </k>
endmodule

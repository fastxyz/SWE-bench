requires "mini-django-admin-url.k"

module READONLY-ADMIN-URL-SPEC
  imports MINI-DJANGO-ADMIN-URL
  imports STRING
  imports MAP
  imports K-EQUAL

  // SPEC-PROVENANCE:
  // - from_prompt: "custom Admin Site" and readonly ForeignKey URL should be
  //   "/custom-admin/..." rather than "/admin/..." => active AdminSite
  //   instance namespace controls admin URL reversal.
  // - from_code: AdminReadonlyField stores self.model_admin, and ModelAdmin
  //   exposes self.admin_site.name.
  claim <k> getAdminUrl(ACTIVE:String, APP:String, MODEL:String, PK:String, OBJ:String, ROUTES:Map)
           => anchor(PREFIX:String +String PK +String "/change/", OBJ) </k>
    requires routeKey(ACTIVE, APP, MODEL) in_keys(ROUTES)
     andBool ROUTES [ routeKey(ACTIVE, APP, MODEL) ] ==K PREFIX
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: the default admin behavior is not reported as broken.
  // - from_code: AdminSite(name='admin') is the default instance namespace.
  claim <k> getAdminUrl("admin", APP:String, MODEL:String, PK:String, OBJ:String, ROUTES:Map)
           => anchor(PREFIX:String +String PK +String "/change/", OBJ) </k>
    requires routeKey("admin", APP, MODEL) in_keys(ROUTES)
     andBool ROUTES [ routeKey("admin", APP, MODEL) ] ==K PREFIX
    [all-path]

  // SPEC-PROVENANCE:
  // - from_code: the helper catches NoReverseMatch and returns str(remote_obj).
  // - frame condition: the V1 change must not turn an unresolved admin URL into
  //   a link to another AdminSite instance.
  claim <k> getAdminUrl(ACTIVE:String, APP:String, MODEL:String, PK:String, OBJ:String, ROUTES:Map)
           => text(OBJ) </k>
    requires notBool routeKey(ACTIVE, APP, MODEL) in_keys(ROUTES)
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: missing current_app is the reported defect.
  // - from_code: pre-fix helper called reverse(url_name, args=[...]) without
  //   current_app, which is modeled here by using DEFAULT instead of ACTIVE.
  claim <k> legacyGetAdminUrl(DEFAULT:String, ACTIVE:String, APP:String, MODEL:String, PK:String, OBJ:String, ROUTES:Map)
           => anchor(DEFAULT_PREFIX:String +String PK +String "/change/", OBJ) </k>
    requires DEFAULT =/=String ACTIVE
     andBool routeKey(DEFAULT, APP, MODEL) in_keys(ROUTES)
     andBool routeKey(ACTIVE, APP, MODEL) in_keys(ROUTES)
     andBool ROUTES [ routeKey(DEFAULT, APP, MODEL) ] ==K DEFAULT_PREFIX
     andBool ROUTES [ routeKey(ACTIVE, APP, MODEL) ] =/=K DEFAULT_PREFIX
    [all-path]
endmodule

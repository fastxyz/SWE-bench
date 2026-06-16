requires "mini-admin-url.k"

module USER-CHANGE-FORM-SPEC
  imports MINI-ADMIN-URL

  // SPEC-PROVENANCE:
  // - prompt: "Accessing the UserAdmin via another model's Admin that has a
  //   reference to User (with to_field set, e.g., to_field=\"uuid\")" =>
  //   current change URL object segment may not be the primary key.
  // - prompt: "This results in the link ... being wrong and thus ending up in
  //   a 404" => password URL must address the primary-key password route.
  // - code: UserAdmin.user_change_password() calls get_object(request,
  //   unquote(id)) with no to_field argument.
  claim
    <k> adminPasswordKey(hasPk(PK:String), ROOT:String, TOFIELD:String)
        => PK ... </k>
    requires adminUnquote(TOFIELD) =/=K PK
    [all-path]

  // SPEC-PROVENANCE:
  // - public-test: auth_tests.test_views.test_user_change_password joins the
  //   help-text relative link against the normal primary-key change URL and
  //   expects the named password-change URL.
  // - code: admin URL generation quotes primary keys before placing them in
  //   object path segments.
  claim
    <k> adminPasswordKey(hasPk(PK:String), ROOT:String, adminQuote(PK))
        => PK ... </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - compatibility: UserChangeForm can be instantiated without a saved
  //   instance in public form tests; V1 preserves the previous fallback link
  //   shape for that case.
  claim
    <k> helpRel(noPk()) => oldPasswordRel() ... </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - proof-local contrast: this is the pre-fix behavior on a to_field URL.
  //   It reaches the to_field value, not the primary key, under the issue's
  //   non-pk object segment condition.
  claim
    <k> oldAdminPasswordKey(ROOT:String, TOFIELD:String)
        => adminUnquote(TOFIELD) ... </k>
    [all-path]
endmodule

requires "mini-urlvalidator.k"

module URLVALIDATOR-SPEC
  imports MINI-URLVALIDATOR

  // SPEC-PROVENANCE:
  // - from_prompt: "reject invalid characters in the username and password"
  // - from_prompt: "any ':', '@', or '/' must be encoded"
  // - from_code: V1 regex excludes these characters from credential fields.
  claim [AUTH-UNCLEAN-REJECTED]:
    <k> validate(url("http", A:Auth, true, true)) => invalid </k>
    requires notBool authFieldsClean(A)
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: "An example URL that should be invalid is http://foo/bar@example.com"
  // - from_code: slash cannot be consumed by userinfo_re.
  claim [AUTH-FORBIDS-SLASH]:
    <k> validate(url("http", user("foo/bar"), true, true)) => invalid </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: raw '@' inside the user/password field must be encoded.
  // - from_code: '@' terminates userinfo and cannot appear inside the field.
  claim [AUTH-FORBIDS-RAW-AT]:
    <k> validate(url("http", user("foo@bar"), true, true)) => invalid </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: raw ':' inside the user/password field must be encoded.
  // - from_default_domain: the first ':' separates username and password.
  claim [AUTH-FORBIDS-EXTRA-COLON]:
    <k> validate(url("http", userPass("user", "pa:ss"), true, true)) => invalid </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: invalid_urls entries must not become valid by appending
  //   '?m=foo@example.com'.
  // - from_code: '?' and path/fragment delimiters are excluded from userinfo_re.
  claim [QUERY-OR-PATH-SMUGGLING-REJECTED]:
    <k> validate(url("http", noAuth, false, true)) => invalid </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_public_tests: ordinary userid:password@example.com is valid.
  // - from_code: the single ':' separator remains in userinfo_re.
  claim [CLEAN-USERINFO-PRESERVED]:
    <k> validate(url("http", userPass("userid", "password"), true, true)) => valid </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: invalid delimiters must be encoded, so encoded delimiters
  //   are acceptable as data.
  // - from_code: '%' is not excluded by userinfo_re.
  claim [PERCENT-ENCODED-DELIMITERS-PRESERVED]:
    <k> validate(url("http", userPass("foo%40", "bar%2f"), true, true)) => valid </k>
    [all-path]
endmodule

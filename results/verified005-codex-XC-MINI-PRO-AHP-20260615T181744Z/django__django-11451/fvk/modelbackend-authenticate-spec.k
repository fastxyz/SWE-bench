requires "mini-auth.k"

module MODEL-BACKEND-AUTHENTICATE-SPEC
  imports MINI-AUTH

  // SPEC-PROVENANCE:
  // - IE-001: no database query when normalized username is None.
  // - IE-002: credentials for another backend may omit username/password.
  // - IE-003: guard runs after username fallback and before lookup/hash.
  claim
    <k> authenticate(noneCred, noneCred, P:MaybePass, DB:DB) => retNone ... </k>
    <events> .List => .List </events>
    [all-path]

  // SPEC-PROVENANCE:
  // - IE-002 and IE-005: password is required for ModelBackend credentials.
  claim
    <k> authenticate(cred(U), KW:MaybeCred, nonePass, DB:DB) => retNone ... </k>
    <events> .List => .List </events>
    [all-path]

  // SPEC-PROVENANCE:
  // - IE-002 and IE-005: password is required after username fallback too.
  claim
    <k> authenticate(noneCred, cred(U), nonePass, DB:DB) => retNone ... </k>
    <events> .List => .List </events>
    [all-path]

  // SPEC-PROVENANCE:
  // - IE-004: complete credentials preserve nonexistent-user dummy hashing.
  claim
    <k> authenticate(cred(U), KW:MaybeCred, pass(P), result(missing)) => retNone ... </k>
    <events> .List => ListItem(lookup(U)) ListItem(dummyHash(P)) </events>
    [all-path]

  // SPEC-PROVENANCE:
  // - IE-004: same preservation when username came from USERNAME_FIELD.
  claim
    <k> authenticate(noneCred, cred(U), pass(P), result(missing)) => retNone ... </k>
    <events> .List => ListItem(lookup(U)) ListItem(dummyHash(P)) </events>
    [all-path]

  // SPEC-PROVENANCE:
  // - IE-005: complete credentials with invalid password do not authenticate.
  claim
    <k> authenticate(cred(U), KW:MaybeCred, pass(P), result(found(User, false, Can)))
        => retNone ... </k>
    <events> .List => ListItem(lookup(U)) ListItem(checkPassword(User, P)) </events>
    [all-path]

  // SPEC-PROVENANCE:
  // - IE-003 and IE-005: username supplied via USERNAME_FIELD follows the same
  //   complete-credential found-user path.
  claim
    <k> authenticate(noneCred, cred(U), pass(P), result(found(User, false, Can)))
        => retNone ... </k>
    <events> .List => ListItem(lookup(U)) ListItem(checkPassword(User, P)) </events>
    [all-path]

  // SPEC-PROVENANCE:
  // - IE-005 and IE-007: complete credentials with valid password still require
  //   user_can_authenticate().
  claim
    <k> authenticate(cred(U), KW:MaybeCred, pass(P), result(found(User, true, false)))
        => retNone ... </k>
    <events> .List => ListItem(lookup(U)) ListItem(checkPassword(User, P)) ListItem(canAuth(User)) </events>
    [all-path]

  // SPEC-PROVENANCE:
  // - IE-003, IE-005, and IE-007: USERNAME_FIELD fallback preserves the same
  //   can-authentication path.
  claim
    <k> authenticate(noneCred, cred(U), pass(P), result(found(User, true, false)))
        => retNone ... </k>
    <events> .List => ListItem(lookup(U)) ListItem(checkPassword(User, P)) ListItem(canAuth(User)) </events>
    [all-path]

  // SPEC-PROVENANCE:
  // - IE-005: complete credentials return the authenticated user only when both
  //   password and user_can_authenticate checks succeed.
  claim
    <k> authenticate(cred(U), KW:MaybeCred, pass(P), result(found(User, true, true)))
        => retUser(User) ... </k>
    <events> .List => ListItem(lookup(U)) ListItem(checkPassword(User, P)) ListItem(canAuth(User)) </events>
    [all-path]

  // SPEC-PROVENANCE:
  // - IE-003 and IE-005: USERNAME_FIELD fallback preserves the same success
  //   path as an explicit username.
  claim
    <k> authenticate(noneCred, cred(U), pass(P), result(found(User, true, true)))
        => retUser(User) ... </k>
    <events> .List => ListItem(lookup(U)) ListItem(checkPassword(User, P)) ListItem(canAuth(User)) </events>
    [all-path]
endmodule

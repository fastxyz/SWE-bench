requires "mini-python-token.k"

module PASSWORD-RESET-TOKEN-SPEC
  imports MINI-PYTHON-TOKEN
  imports INT
  imports BOOL
  imports STRING
  imports K-EQUAL

  // Claim: HASH-USES-CONFIGURED-EMAIL
  // SPEC-PROVENANCE:
  // - E1/E2: the issue requires the user's email address to be included in
  //   PasswordResetTokenGenerator._make_hash_value().
  // - E4/E5: the configured email field comes from get_email_field_name().
  // - from_code: V1 computes email_field = user.get_email_field_name(), then
  //   email = getattr(user, email_field, '') or ''.
  claim
    <k> makeHashValue(user(PK, PASSWORD, LOGIN, FIELD, field(FIELD, email(EMAIL))), T)
      => hashInput(PK, PASSWORD, LOGIN, T, EMAIL)
      ... </k>
    [all-path]

  // Claim: MISSING-EMAIL-DEFINED
  // SPEC-PROVENANCE:
  // - E3: AbstractBaseUser does not force a concrete email attribute.
  // - from_code: getattr(..., '') supplies the absent-field fallback.
  claim
    <k> makeHashValue(user(PK, PASSWORD, LOGIN, FIELD, missingFields()), T)
      => hashInput(PK, PASSWORD, LOGIN, T, "")
      ... </k>
    [all-path]

  // Claim: NULL-EMAIL-DEFINED
  // SPEC-PROVENANCE:
  // - E3 plus the named no-address convention in INTENT_SPEC.md.
  // - from_code: "or ''" maps null-like email values to the empty component.
  claim
    <k> makeHashValue(user(PK, PASSWORD, LOGIN, FIELD, field(FIELD, nullEmail())), T)
      => hashInput(PK, PASSWORD, LOGIN, T, "")
      ... </k>
    [all-path]

  // Claim: SAME-STATE-VALIDATES
  // SPEC-PROVENANCE:
  // - E6/E7: generated tokens validate for unchanged, unexpired user state.
  // - from_code: check_token() recomputes _make_token_with_timestamp(user, ts)
  //   and compares it in constant time before enforcing timeout.
  claim
    <k> checkToken(USER, token(T, digest(hashValue(USER, T))), NOW, TIMEOUT)
      => true
      ... </k>
    requires (NOW -Int T) <=Int TIMEOUT
    [all-path]

  // Claim: EMAIL-CHANGE-REJECTED
  // SPEC-PROVENANCE:
  // - E1: a token generated before an email change must be rejected after the
  //   concrete configured email value changes.
  // - E2: email is in the HMAC input, so the recomputed digest differs.
  claim
    <k> checkToken(
          user(PK, PASSWORD, LOGIN, FIELD, field(FIELD, email(NEW_EMAIL))),
          token(T, digest(hashValue(user(PK, PASSWORD, LOGIN, FIELD, field(FIELD, email(OLD_EMAIL))), T))),
          NOW,
          TIMEOUT
        )
      => false
      ... </k>
    requires notBool (OLD_EMAIL ==String NEW_EMAIL)
     andBool (NOW -Int T) <=Int TIMEOUT
    [all-path]

  // Claim: PASSWORD-CHANGE-REJECTED
  // SPEC-PROVENANCE:
  // - E6/E7: the existing password-hash invalidator is preserved.
  claim
    <k> checkToken(
          user(PK, NEW_PASSWORD, LOGIN, FIELD, field(FIELD, email(EMAIL))),
          token(T, digest(hashValue(user(PK, OLD_PASSWORD, LOGIN, FIELD, field(FIELD, email(EMAIL))), T))),
          NOW,
          TIMEOUT
        )
      => false
      ... </k>
    requires notBool (OLD_PASSWORD ==String NEW_PASSWORD)
     andBool (NOW -Int T) <=Int TIMEOUT
    [all-path]

  // Claim: EXPIRED-TOKEN-REJECTED
  // SPEC-PROVENANCE:
  // - E6/E7: timeout behavior remains a frame condition.
  claim
    <k> checkToken(USER, token(T, digest(hashValue(USER, T))), NOW, TIMEOUT)
      => false
      ... </k>
    requires (NOW -Int T) >Int TIMEOUT
    [all-path]
endmodule

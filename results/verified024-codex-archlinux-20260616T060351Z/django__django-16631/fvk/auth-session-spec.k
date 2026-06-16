requires "mini-auth-session.k"

module MINI-AUTH-SESSION-SPEC
  imports MINI-AUTH-SESSION

  // SPEC-PROVENANCE:
  // - from_prompt: "SECRET_KEY_FALLBACKS is not used for sessions" =>
  //   an auth session hash generated with an old key in SECRET_KEY_FALLBACKS
  //   must validate during key rotation.
  // - from_docs: SECRET_KEY is used by AbstractBaseUser.get_session_auth_hash()
  //   and old keys in SECRET_KEY_FALLBACKS keep affected uses valid.
  // - from_code: current hash is hmac(current secret, password field).
  claim <k> getUser(session(UID:Int, true, some(hmac(CUR:Int, PWD:Int)), CYCLED:Bool),
                    user(UID, PWD, true, FBS:Keys),
                    CUR)
        => authenticated(session(UID, true, some(hmac(CUR, PWD)), CYCLED)) </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt/public hint: "we should check fallback session hashes" =>
  //   fallback-key session hashes authenticate.
  // - from_hint: fallback-valid sessions should not be invalidated again when
  //   possible; rewriting to the current hash discharges that preservation.
  claim <k> getUser(session(UID:Int, true, some(hmac(OLD:Int, PWD:Int)), CYCLED:Bool),
                    user(UID, PWD, true, FBS:Keys),
                    CUR:Int)
        => authenticated(session(UID, true, some(hmac(CUR, PWD)), true)) </k>
    requires OLD =/=Int CUR
     andBool fallbackMatches(some(hmac(OLD, PWD)), PWD, FBS)
    [all-path]

  // SPEC-PROVENANCE:
  // - from_auth_contract: password changes invalidate sessions because the
  //   auth hash is derived from the current password field.
  claim <k> getUser(session(UID:Int, true, some(hmac(OLD:Int, OLDPWD:Int)), CYCLED:Bool),
                    user(UID, NEWPWD:Int, true, FBS:Keys),
                    CUR:Int)
        => anonymous(session(UID, false, noHash, true)) </k>
    requires OLDPWD =/=Int NEWPWD
     andBool notBool fallbackMatches(some(hmac(OLD, OLDPWD)), NEWPWD, FBS)
     andBool OLD =/=Int CUR
    [all-path]

  // SPEC-PROVENANCE:
  // - from_public_compatibility: custom user objects may implement only
  //   get_session_auth_hash(); fallback support is optional.
  claim <k> getUser(session(UID:Int, true, some(hmac(OLD:Int, PWD:Int)), CYCLED:Bool),
                    user(UID, PWD, false, FBS:Keys),
                    CUR:Int)
        => anonymous(session(UID, false, noHash, true)) </k>
    requires OLD =/=Int CUR
    [all-path]

  // SPEC-PROVENANCE:
  // - from_login_contract: login reuses same-user session data unless the
  //   existing session corresponds to another user or an invalid auth hash.
  // - from_prompt: fallback hashes are valid session hashes during rotation.
  claim <k> login(session(UID:Int, true, some(hmac(OLD:Int, PWD:Int)), CYCLED:Bool),
                  user(UID, PWD, true, FBS:Keys),
                  CUR:Int)
        => reuse(session(UID, true, some(hmac(CUR, PWD)), CYCLED)) </k>
    requires OLD =/=Int CUR
     andBool fallbackMatches(some(hmac(OLD, PWD)), PWD, FBS)
    [all-path]

  // SPEC-PROVENANCE:
  // - from_login_contract: another user's existing session must be flushed.
  claim <k> login(session(OLDUID:Int, true, H:MaybeHash, CYCLED:Bool),
                  user(UID:Int, PWD:Int, SUPPORTS:Bool, FBS:Keys),
                  CUR:Int)
        => flushThenLogin(session(UID, true, some(hmac(CUR, PWD)), true)) </k>
    requires OLDUID =/=Int UID
    [all-path]
endmodule

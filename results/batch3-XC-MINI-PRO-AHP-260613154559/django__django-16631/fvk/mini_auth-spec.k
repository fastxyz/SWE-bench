// mini_auth-spec.k — the reachability claims (function contracts + loop
// circularity) for the V1 fix of django__django-16631, over mini_auth.k.
//
// CONSTRUCTED, NOT MACHINE-CHECKED.  Run-commands in PROOF.md.

requires "mini_auth.k"

module MINI-AUTH-SPEC-SYNTAX
  imports MINI-AUTH-SYNTAX
endmodule

module VERIFICATION
  imports MINI-AUTH-SPEC-SYNTAX
  imports MINI-AUTH
  imports MAP-SYMBOLIC
  imports K-EQUAL

  // Boolean associativity of `or` is the only extra fact the SCAN step needs;
  // Z3 discharges it.  inList's two defining equations live in mini_auth.k.
endmodule

module MINI-AUTH-SPEC
  imports VERIFICATION

  // =========================================================================
  // (HASH-EQ)  base_user.py refactor preserves the legacy hash.
  //   new  = _get_session_auth_hash()          == salted_hmac(salt,pwd,secret=None)
  //   old  = legacy salted_hmac(salt,pwd)       (secret argument omitted -> None)
  // Both must resolve to H3(SALT,PWD,SK).  This is the backward-compatibility
  // obligation: cookies minted before the upgrade must still verify.
  // =========================================================================
  claim <k> new = H3(SALT, PWD, resolve(eps)) ;     // V1 code path
            old = H3(SALT, PWD, resolve(eps)) ;      // pre-fix code path
        => .K ... </k>
        <store> STORE
             => STORE [ new <- H3(SALT, PWD, SK) ]
                      [ old <- H3(SALT, PWD, SK) ] </store>
        <secret> SK:Val </secret>
        ensures notBool (SALT ==K eps) andBool notBool (PWD ==K eps)
        [all-path]

  // =========================================================================
  // (SCAN-LOOP)  the fallback search loop — the circularity.
  //   Models:  any(constant_time_compare(h, x)
  //                for x in user.get_session_auth_fallback_hash())
  // Generalized over the accumulator `found = F` and the *remaining* list
  // `fb = FB`.  Closed form: found' = F or inList(H, FB).
  // No counter side condition is needed (a List recurses structurally to .List);
  // the only soundness need is that FB is a finite List, which it is by sort.
  // =========================================================================
  claim <k> while (notEmpty(fb)) {
                 found = found or (head(fb) == h) ;
                 fb = tail(fb) ;
            } => .K ... </k>
        <store>
            found |-> (F:Bool => F orBool inList(H, FB))
            fb    |-> (FB:List => .List)
            h     |-> H:Val
        </store>
        [all-path]

  // =========================================================================
  // (GETUSER)  the verification fragment of auth.get_user(), as a contract.
  //   Inputs:  h  = stored session hash (eps if absent/empty),
  //            hc = user.get_session_auth_hash() (current SECRET_KEY),
  //            fb = list of fallback-key hashes (= get_session_auth_fallback_hash()).
  //   Outputs (the spec observation):
  //            outcome in {KEEP, UPGRADE, FLUSH},  stored = resulting cookie hash.
  //
  //   Postcondition (proved):
  //     outcome = KEEP    & stored = HC   if  H != eps  and  H == HC
  //     outcome = UPGRADE & stored = HC   if  H != eps  and  H != HC  and  inList(H, FB)
  //     outcome = FLUSH   & stored = eps  otherwise (H == eps, or no match)
  //
  //   i.e. the user is KEPT (KEEP or UPGRADE) iff  H != eps and H in {HC} ++ FB;
  //   and a fallback match UPGRADEs the cookie to the current-key hash HC.
  // =========================================================================
  claim <k>
          verified = false ;
          if (h != eps) { verified = (h == hc) ; } else { }
          if (not verified) {
             found = false ;
             if (h != eps) {                       // models `session_hash and ...`
                while (notEmpty(fb)) {
                   found = found or (head(fb) == h) ;
                   fb = tail(fb) ;
                }
             } else { }
             if (found) {
                stored = hc ; outcome = UPGRADE ;   // cycle_key + write current hash
             } else {
                stored = eps ; outcome = FLUSH ;     // flush + user = None
             }
          } else {
             stored = h ; outcome = KEEP ;           // session left unchanged
          }
        => .K ... </k>
        <store>
            h        |-> H:Val
            hc       |-> HC:Val
            fb       |-> (_:List => ?_:List)
            verified |-> (_ => ?_:Bool)
            found    |-> (_ => ?_:Bool)
            stored   |-> (?STORED:Val)
            outcome  |-> (?OUT:Outcome)
        </store>
        ensures
          (   (?OUT ==K KEEP)    andBool (?STORED ==K HC)
              andBool notBool (H ==K eps) andBool (H ==K HC) )
          orBool
          (   (?OUT ==K UPGRADE) andBool (?STORED ==K HC)
              andBool notBool (H ==K eps) andBool notBool (H ==K HC)
              andBool inList(H, FB0) )
          orBool
          (   (?OUT ==K FLUSH)   andBool (?STORED ==K eps)
              andBool ( (H ==K eps)
                        orBool (notBool (H ==K HC) andBool notBool inList(H, FB0)) ) )
        // FB0 is the *initial* fallback list (the loop consumes `fb` to .List).
        [all-path]
endmodule

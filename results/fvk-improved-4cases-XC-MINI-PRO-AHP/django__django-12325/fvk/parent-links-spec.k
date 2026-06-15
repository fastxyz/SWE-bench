// parent-links-spec.k
// =============================================================================
// K reachability claims for the V1 parent-link selection loop, over the
// mini-python.k fragment.  See SPEC.md for the public intent ledger and
// PROOF.md for the constructed proof.
//
// The modelled loop body (mini-python), for one fixed target model with flag
// list L = b_1 : ... : b_n : .BList, processed in order:
//
//   chosen = 0 ;          // parent_links.get(key) == None
//   cpl    = false ;      // chosen's parent_link flag (irrelevant while chosen==0)
//   j      = 1 ;          // 1-based position of the current field
//   while ( not isEmpty(l) ) {
//       h = head(l) ;
//       if ( chosen == 0 or not cpl ) {   // store iff existing is None OR not parent_link
//           chosen = j ;
//           cpl    = h ;
//       }
//       l = tail(l) ;
//       j = j + 1 ;
//   }
//   // result: `chosen` is the selected field's position, `cpl` its flag.
// =============================================================================

module PARENT-LINKS-SPEC
  imports MINI-PYTHON

  // ----- closed-form helper functions (the SPECIFICATION of the selection) -----
  // containsTrue(L): some field targeting this parent is an explicit parent link.
  syntax Bool ::= containsTrue(BList) [function, total]
  rule containsTrue(.BList)      => false
  rule containsTrue(true  : _)   => true
  rule containsTrue(false : T)   => containsTrue(T)

  // lenB(L): number of OneToOneFields targeting this parent.
  syntax Int ::= lenB(BList) [function, total]
  rule lenB(.BList) => 0
  rule lenB(_ : T)  => 1 +Int lenB(T)

  // firstTrue(L): 1-based position of the FIRST explicit parent link, else 0.
  syntax Int ::= firstTrue(BList) [function, total]
  rule firstTrue(.BList)    => 0
  rule firstTrue(true  : _) => 1
  rule firstTrue(false : T) => #if firstTrue(T) ==Int 0
                               #then 0 #else 1 +Int firstTrue(T) #fi

  // selectResult(L): the position the loop MUST end up choosing, from a fresh
  // start.  This is the intended contract:
  //   * if any field is parent_link=True  -> the FIRST such field;
  //   * else if there is at least one field -> the LAST field (legacy tie-break);
  //   * else (no fields) -> 0 (None; Django auto-creates the *_ptr link).
  syntax Int ::= selectResult(BList) [function, total]
  rule selectResult(L) => #if   containsTrue(L) #then firstTrue(L)
                          #else #if lenB(L) >Int 0 #then lenB(L) #else 0 #fi #fi

  // remainResult(C,P,J,L): the position the loop ends on when RESUMED mid-way
  // with chosen=C, cpl=P, position counter=J, remaining flags=L.  Used as the
  // loop invariant's closed form.  Elements of L occupy absolute positions
  // J, J+1, ..., J+lenB(L)-1, so a within-L 1-based index k maps to J-1+k.
  syntax Int ::= remainResult(Int, Bool, Int, BList) [function, total]
  rule remainResult(C, P, _, _) => C
       requires C =/=Int 0 andBool P
  rule remainResult(C, P, J, L) =>
         #if   containsTrue(L) #then J -Int 1 +Int firstTrue(L)
         #else #if lenB(L) >Int 0 #then J -Int 1 +Int lenB(L) #else C #fi #fi
       requires notBool (C =/=Int 0 andBool P)

  // =========================================================================
  // (SELECT) — top-level function contract.
  //
  // SPEC-PROVENANCE:
  // - from_prompt: "pk setup for MTI to parent get confused by multiple
  //     OneToOne references ... document_ptr = OneToOneField(..., parent_link=True);
  //     origin = OneToOneField(...) produces ImproperlyConfigured ... order seems
  //     to matter ... we have explicit parent_link marker"
  //     => ORDERING/WINNER obligation: when several OneToOneFields target the
  //        parent, the explicit parent_link=True field is selected regardless of
  //        declaration order.  Encoded as: containsTrue(L) ==> result == firstTrue(L).
  // - from_docs:  docs/topics/db/models.txt "You can override that field by
  //     declaring your own OneToOneField with parent_link=True"; the auto link
  //     `*_ptr` is parent_link=True, primary_key=True
  //     => the explicit parent_link field is THE link to the parent.
  // - from_code:  per-key dict update with the V1 store-guard
  //     `existing is not None and existing.remote_field.parent_link`.
  // - from_default_domain: "first/last winner" of a fold; empty input -> None.
  // - conflicts: the lone-unmarked case selectResult(false:.BList)=1 keeps the
  //     field selected (so options.py raises "Add parent_link=True"); a thread
  //     comment calls that a bug.  Resolved against docs (deprecation) — see
  //     FINDINGS.md F1 and the side-by-side derivation in PROOF.md.
  // =========================================================================
  claim <k> chosen = 0 ; cpl = false ; j = 1 ;
            while ( not isEmpty(l) ) {
              h = head(l) ;
              if ( chosen == 0 or not cpl ) { chosen = j ; cpl = h ; }
              l = tail(l) ;
              j = j + 1 ;
            }
        => . </k>
        <store> chosen |-> (0 => selectResult(L0))
                cpl    |-> (false => containsTrue(L0))
                j      |-> (1 => 1 +Int lenB(L0))
                h      |-> (?_:Bool)
                l      |-> (L0:BList => .BList) </store>
    [all-path]

  // =========================================================================
  // (LOOP) — loop-invariant circularity, generalized over chosen=C, cpl=P,
  // counter=J, remaining=L.  K treats this claim as its own coinduction
  // hypothesis; the genuine =>+ step is the guard evaluation each iteration.
  //
  // SPEC-PROVENANCE:
  // - from_prompt/from_code: invariant "once an explicit parent link is chosen
  //     it is never overwritten; otherwise the last field stays chosen".
  // - soundness side condition: 1 <= J (positions are 1-based) and, when a parent
  //     link is already locked, C is its absolute position (C =/=Int 0).
  // =========================================================================
  claim <k> while ( not isEmpty(l) ) {
              h = head(l) ;
              if ( chosen == 0 or not cpl ) { chosen = j ; cpl = h ; }
              l = tail(l) ;
              j = j + 1 ;
            }
        => . </k>
        <store> chosen |-> (C:Int  => remainResult(C, P, J, L))
                cpl    |-> (P:Bool => #if containsTrue(L) orBool (C =/=Int 0 andBool P)
                                      #then true #else false #fi)
                j      |-> (J:Int  => J +Int lenB(L))
                h      |-> (?_:Bool)
                l      |-> (L:BList => .BList) </store>
    requires J >=Int 1
     andBool (notBool (C =/=Int 0 andBool P) orBool C <Int J)
    [all-path]

  // =========================================================================
  // (CASE-A) — the reported failing order, fully concrete (no induction):
  //   document_ptr (parent_link=True) declared BEFORE origin (parent_link=False)
  //   L0 = true : false : .BList   ==>   chosen == 1  (document_ptr wins)
  // =========================================================================
  claim <k> chosen = 0 ; cpl = false ; j = 1 ;
            while ( not isEmpty(l) ) {
              h = head(l) ;
              if ( chosen == 0 or not cpl ) { chosen = j ; cpl = h ; }
              l = tail(l) ;
              j = j + 1 ;
            }
        => . </k>
        <store> chosen |-> (0 => 1) cpl |-> (false => true)
                j |-> (1 => 3) h |-> (?_:Bool)
                l |-> (true : false : .BList => .BList) </store>
    [all-path]

  // =========================================================================
  // (CASE-B) — the reported working order, fully concrete (no induction):
  //   origin (False) declared BEFORE document_ptr (True)
  //   L0 = false : true : .BList   ==>   chosen == 2  (document_ptr STILL wins)
  // Together with (CASE-A) this proves order-independence of the winner.
  // =========================================================================
  claim <k> chosen = 0 ; cpl = false ; j = 1 ;
            while ( not isEmpty(l) ) {
              h = head(l) ;
              if ( chosen == 0 or not cpl ) { chosen = j ; cpl = h ; }
              l = tail(l) ;
              j = j + 1 ;
            }
        => . </k>
        <store> chosen |-> (0 => 2) cpl |-> (false => true)
                j |-> (1 => 3) h |-> (?_:Bool)
                l |-> (false : true : .BList => .BList) </store>
    [all-path]

  // =========================================================================
  // (CASE-LONE) — the lone unmarked field (test_missing_parent_link / the
  // thread's "simpler case"): L0 = false : .BList ==> chosen == 1, cpl == false.
  // The field is STILL selected, so options.py raises "Add parent_link=True".
  // This pins the deliberately-preserved deprecation behavior (FINDINGS F1).
  // =========================================================================
  claim <k> chosen = 0 ; cpl = false ; j = 1 ;
            while ( not isEmpty(l) ) {
              h = head(l) ;
              if ( chosen == 0 or not cpl ) { chosen = j ; cpl = h ; }
              l = tail(l) ;
              j = j + 1 ;
            }
        => . </k>
        <store> chosen |-> (0 => 1) cpl |-> (false => false)
                j |-> (1 => 2) h |-> (?_:Bool)
                l |-> (false : .BList => .BList) </store>
    [all-path]
endmodule

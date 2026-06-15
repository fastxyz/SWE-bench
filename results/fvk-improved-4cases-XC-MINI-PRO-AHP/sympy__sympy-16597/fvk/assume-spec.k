// assume-spec.k
// ---------------------------------------------------------------------------
// K reachability claims for the V1 fix to sympy/core/assumptions.py:
//     'rational -> real'   ==>   'rational -> real & finite'
//
// Each claim runs the forward-chaining closure (`close`) of mini-assume.k from
// an initial knowledge base to its fixpoint. The closure is a normal form, so
// `<k> close </k>` is carried unchanged on both sides; a claim that lands on a
// concrete facts map (rather than `#inconsistent`) also certifies consistency.
//
// Labelled [all-path]: from the initial KB *every* execution of the
// (confluent, monotone) closure reaches the stated fixpoint.
// Status: CONSTRUCTED, NOT MACHINE-CHECKED (see PROOF.md).
// ---------------------------------------------------------------------------

module ASSUME-SPEC
  imports MINI-ASSUME

  // -------------------------------------------------------------------------
  // SPEC-PROVENANCE  (EVEN-FINITE)  -- the reported bug
  // - from_prompt: "m = Symbol('m', even=True) ... print(m.is_finite) -> None"
  //                "I would expect that a number should be finite before it can be even."
  //                => obligation: even=True must deduce finite=True.
  // - from_code:   even == integer & !odd ; integer -> rational ; (FIX) rational -> finite
  // -------------------------------------------------------------------------
  claim <k> close </k>
        <facts> even |-> true
             => even     |-> true
                integer  |-> true
                rational |-> true
                real     |-> true
                finite   |-> true </facts>   [all-path]

  // -------------------------------------------------------------------------
  // SPEC-PROVENANCE  (INTEGER-FINITE)  -- the second reported case
  // - from_prompt: "i = Symbol('i', integer=True) ... print(i.is_finite) -> None"
  //                => obligation: integer=True must deduce finite=True.
  // - from_code:   integer -> rational ; (FIX) rational -> finite
  // -------------------------------------------------------------------------
  claim <k> close </k>
        <facts> integer |-> true
             => integer  |-> true
                rational |-> true
                real     |-> true
                finite   |-> true </facts>   [all-path]

  // -------------------------------------------------------------------------
  // SPEC-PROVENANCE  (RATIONAL-FINITE)  -- the node the fix is attached to
  // - from_prompt(hint): "it should be safe to add finite to rational"
  //                => obligation: rational=True deduces real=True and finite=True.
  // - from_code:   (FIX) rational -> real & finite
  // -------------------------------------------------------------------------
  claim <k> close </k>
        <facts> rational |-> true
             => rational |-> true
                real     |-> true
                finite   |-> true </facts>   [all-path]

  // -------------------------------------------------------------------------
  // SPEC-PROVENANCE  (OO-CONSISTENT)  -- the fix must not break S.Infinity
  // - from_code:   Infinity declares is_positive=True, is_infinite=True
  //                (sympy/core/numbers.py:2658-2659).
  // - from_test:   test_infinity asserts oo stays a CONSISTENT object.
  //   obligation: closing oo's base facts terminates WITHOUT #inconsistent and
  //   yields finite=False, rational=False, integer=False (all correct for oo),
  //   plus the documented consequence irrational=True (irrational == real & !rational
  //   with the pre-existing extended-real choice oo.is_real=True). See FINDINGS F1.
  // -------------------------------------------------------------------------
  claim <k> close </k>
        <facts> positive |-> true  infinite |-> true
             => positive    |-> true
                infinite    |-> true
                nonnegative |-> true
                real        |-> true
                finite      |-> false
                rational    |-> false
                integer     |-> false
                even        |-> false
                odd         |-> false
                irrational  |-> true
                noninteger  |-> true </facts>   [all-path]

  // -------------------------------------------------------------------------
  // SPEC-PROVENANCE  (CLASH-DETECTED)  -- the safety net that rules out the
  // rejected alternatives `real -> finite` and `complex -> finite`.
  // - from_code:   infinite -> !finite  (sympy/core/assumptions.py:198).
  //   obligation: any object that is simultaneously infinite and finite is
  //   InconsistentAssumptions. Since S.Infinity/S.NegativeInfinity (real, via
  //   is_positive/is_negative) and S.ComplexInfinity (complex) are all infinite,
  //   attaching `finite` to `real` or `complex` would force exactly this clash.
  //   See PROOF.md side-by-side derivation and FINDINGS F4.
  // -------------------------------------------------------------------------
  claim <k> close </k>
        <facts> infinite |-> true  finite |-> true </facts>
     => <k> #inconsistent </k>
        <facts> infinite |-> true  finite |-> true </facts>   [all-path]
endmodule

// mini_assumptions-spec.k
// =====================================================================
// Reachability claims over mini_assumptions.k.  These formalize the
// intent of the V1 fix (issue sympy-16597) and the safety obligations.
//
// Constructed, not machine-checked.  Run-commands in ../fvk/PROOF.md.
// =====================================================================
requires "mini_assumptions.k"

module MINI-ASSUMPTIONS-SPEC-SYNTAX
  imports MINI-ASSUMPTIONS-SYNTAX
endmodule

module VERIFICATION
  imports MINI-ASSUMPTIONS-SPEC-SYNTAX
  imports MINI-ASSUMPTIONS
  imports MAP
  imports K-EQUAL
endmodule

module MINI-ASSUMPTIONS-SPEC
  imports VERIFICATION

  // -----------------------------------------------------------------
  // (PO1) DEDUCE-EVEN  —  the issue's primary obligation.
  // SPEC-PROVENANCE:
  //  - from_prompt: "a.is_even does not imply a.is_finite ... I would
  //    expect that a number should be finite before it can be even."
  //    => Symbol('m', even=True).is_finite must be True.
  //  - from_code: even -> integer -> rational -> finite (assumptions.py,
  //    with the V1 line 'rational -> finite').
  // Telling even=True and closing reaches a KB with finite |-> true and
  // status still ok.
  // -----------------------------------------------------------------
  claim <k> tell(even, true) close => .K ... </k>
        <kb> .Map => ?KB:Map </kb>
        <status> ok </status>
    ensures (finite in_keys(?KB)) andBool (?KB[finite] ==K true)
            andBool (integer in_keys(?KB)) andBool (?KB[integer] ==K true)
            andBool (rational in_keys(?KB)) andBool (?KB[rational] ==K true)
    [all-path]

  // -----------------------------------------------------------------
  // (PO2) DEDUCE-INT  —  the issue's second case (the i = Symbol(integer=True)).
  // SPEC-PROVENANCE:
  //  - from_prompt (hint): "i = Symbol('i', integer=True); print(i.is_finite) -> None"
  //  - from_code: integer -> rational -> finite.
  // -----------------------------------------------------------------
  claim <k> tell(integer, true) close => .K ... </k>
        <kb> .Map => ?KB:Map </kb>
        <status> ok </status>
    ensures (finite in_keys(?KB)) andBool (?KB[finite] ==K true)
    [all-path]

  // -----------------------------------------------------------------
  // (PO3) DEDUCE-RAT  —  the generalized obligation the hint endorses.
  // SPEC-PROVENANCE:
  //  - from_docs (hint): "it should be safe to add finite to rational".
  // -----------------------------------------------------------------
  claim <k> tell(rational, true) close => .K ... </k>
        <kb> .Map => ?KB:Map </kb>
        <status> ok </status>
    ensures (finite in_keys(?KB)) andBool (?KB[finite] ==K true)
    [all-path]

  // -----------------------------------------------------------------
  // (PO5) CONSISTENT-OO  —  the key SAFETY obligation: the singletons that
  // hard-code (positive=True, infinite=True) must still build, i.e. the
  // new rule must NOT drive their KB to `inconsistent`.  It also pins the
  // forced consequences reported in FINDINGS.md (F2).
  // SPEC-PROVENANCE:
  //  - from_code: Infinity sets is_positive=True, is_infinite=True
  //    (numbers.py:2657-2660); ManagedProperties builds default_assumptions
  //    via StdFactKB(defs) at class-creation time.
  //  - conflicts: none — proven `ok` below.
  // -----------------------------------------------------------------
  claim <k> tell(positive, true) tell(infinite, true) close => .K ... </k>
        <kb> .Map => ?KB:Map </kb>
        <status> ok </status>                         // <-- the safety crux: stays ok
    ensures (finite in_keys(?KB))     andBool (?KB[finite] ==K false)
            andBool (rational in_keys(?KB))   andBool (?KB[rational] ==K false)
            andBool (integer in_keys(?KB))    andBool (?KB[integer] ==K false)
            andBool (even in_keys(?KB))       andBool (?KB[even] ==K false)
            andBool (irrational in_keys(?KB)) andBool (?KB[irrational] ==K true)   // F2: forced, consistent
            andBool (noninteger in_keys(?KB)) andBool (?KB[noninteger] ==K true)
    [all-path]

  // -----------------------------------------------------------------
  // (PO7) NO-CONVERSE  —  guards against over-strengthening.  Telling only
  // finite=True must NOT make rational known (the rule is one-directional:
  // rational -> finite, NOT finite -> rational).  A bare finite symbol must
  // keep rational == None (absent).
  // SPEC-PROVENANCE:
  //  - from_code: only 'rational -> finite' was added; the converse is absent.
  // -----------------------------------------------------------------
  claim <k> tell(finite, true) close => .K ... </k>
        <kb> .Map => ?KB:Map </kb>
        <status> ok </status>
    ensures notBool (rational in_keys(?KB))
            andBool notBool (integer in_keys(?KB))
            andBool notBool (even in_keys(?KB))
    [all-path]
endmodule

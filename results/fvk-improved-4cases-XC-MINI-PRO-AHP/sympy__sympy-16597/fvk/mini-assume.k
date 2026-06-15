// mini-assume.k
// ---------------------------------------------------------------------------
// A minimal K semantics for the *fragment* of SymPy's old-assumptions engine
// (sympy/core/assumptions.py :: `_assume_rules`, deduced by
//  sympy/core/facts.py :: FactRules/FactKB) that the V1 fix touches.
//
// What the real code does: every Basic object owns a `StdFactKB`, a 3-valued
// knowledge base over assumption atoms (`is_even`, `is_integer`, ...). Setting
// some atoms (e.g. even=True) triggers `deduce_all_facts`, the forward-chaining
// closure of `_assume_rules` (alpha rules `a->b`, beta rules `a&b->c`, and the
// automatically-added contrapositives), which either reaches a fixpoint or
// raises `InconsistentAssumptions`.
//
// We model exactly that closure, restricted to the atoms the four proof
// obligations mention: even, odd, integer, rational, real, finite, infinite,
// irrational, noninteger, positive, nonnegative. Each atom maps to a Bool
// (true / false); an ABSENT key means "unknown" (SymPy's None). The closure is
// monotone (keys are only added, never overwritten) and the atom set is finite,
// so it terminates. A contradiction (a rule whose consequent is already present
// with the opposite value) rewrites the driver to `#inconsistent` — this models
// `InconsistentAssumptions`.
//
// MVP stopgap: this is a faithful *fragment*, not the whole FactRules engine.
// It is the placeholder for a full in-K model of facts.py; kept small,
// commented, and limited to the rules the claims exercise.
// ---------------------------------------------------------------------------

module MINI-ASSUME-SYNTAX
  imports BOOL
  imports MAP

  // The driver sits in <k>: `close` runs forward chaining to a fixpoint.
  syntax Pgm   ::= "close"
  syntax KItem ::= "#inconsistent"   // models InconsistentAssumptions
endmodule

module MINI-ASSUME
  imports MINI-ASSUME-SYNTAX
  imports BOOL
  imports MAP

  configuration
    <k>     $PGM:Pgm    </k>
    <facts> $FACTS:Map  </facts>      // assumption-atom |-> Bool ; absent = unknown

  // =========================================================================
  // POSITIVE (alpha) rules  --  a=true  =>  b=true
  // Each fires only while `close` is active and the consequent is still UNKNOWN
  // (`notBool (b in_keys REST)`), so the map grows monotonically.
  // =========================================================================

  // even -> integer            (from `even == integer & !odd`)
  rule <k> close </k>
       <facts> even |-> true REST => even |-> true integer |-> true REST </facts>
    requires notBool(integer in_keys(REST))

  // odd -> integer             (from `odd == integer & !even`)
  rule <k> close </k>
       <facts> odd |-> true REST => odd |-> true integer |-> true REST </facts>
    requires notBool(integer in_keys(REST))

  // integer -> rational
  rule <k> close </k>
       <facts> integer |-> true REST => integer |-> true rational |-> true REST </facts>
    requires notBool(rational in_keys(REST))

  // rational -> real
  rule <k> close </k>
       <facts> rational |-> true REST => rational |-> true real |-> true REST </facts>
    requires notBool(real in_keys(REST))

  // rational -> finite          <==== THE V1 FIX ('rational -> real & finite')
  rule <k> close </k>
       <facts> rational |-> true REST => rational |-> true finite |-> true REST </facts>
    requires notBool(finite in_keys(REST))

  // positive -> nonnegative     (from `positive == nonnegative & nonzero`)
  rule <k> close </k>
       <facts> positive |-> true REST => positive |-> true nonnegative |-> true REST </facts>
    requires notBool(nonnegative in_keys(REST))

  // nonnegative -> real         (from `nonnegative == real & !negative`)
  rule <k> close </k>
       <facts> nonnegative |-> true REST => nonnegative |-> true real |-> true REST </facts>
    requires notBool(real in_keys(REST))

  // infinite -> finite=false    (from `infinite -> !finite`)
  rule <k> close </k>
       <facts> infinite |-> true REST => infinite |-> true finite |-> false REST </facts>
    requires notBool(finite in_keys(REST))

  // irrational == real & !rational   (backward direction: real & !rational -> irrational)
  rule <k> close </k>
       <facts> real |-> true rational |-> false REST
            => real |-> true rational |-> false irrational |-> true REST </facts>
    requires notBool(irrational in_keys(REST))

  // noninteger == real & !integer    (backward direction: real & !integer -> noninteger)
  rule <k> close </k>
       <facts> real |-> true integer |-> false REST
            => real |-> true integer |-> false noninteger |-> true REST </facts>
    requires notBool(noninteger in_keys(REST))

  // =========================================================================
  // NEGATIVE (contrapositive) rules  --  the engine adds these automatically.
  // =========================================================================

  // contrapositive of (rational -> finite):  finite=false => rational=false   [FIX]
  rule <k> close </k>
       <facts> finite |-> false REST => finite |-> false rational |-> false REST </facts>
    requires notBool(rational in_keys(REST))

  // contrapositive of (integer -> rational): rational=false => integer=false
  rule <k> close </k>
       <facts> rational |-> false REST => rational |-> false integer |-> false REST </facts>
    requires notBool(integer in_keys(REST))

  // contrapositive of (even -> integer):     integer=false => even=false
  rule <k> close </k>
       <facts> integer |-> false REST => integer |-> false even |-> false REST </facts>
    requires notBool(even in_keys(REST))

  // contrapositive of (odd -> integer):      integer=false => odd=false
  rule <k> close </k>
       <facts> integer |-> false REST => integer |-> false odd |-> false REST </facts>
    requires notBool(odd in_keys(REST))

  // =========================================================================
  // CLASH rules  --  model InconsistentAssumptions. A clash exists when an
  // antecedent is true but its (already-known) consequent holds the opposite
  // value. If ANY of these matches, the KB is inconsistent.
  // =========================================================================

  // rational=true but finite=false   (the rule that would fire if `real -> finite`
  //                                    or `complex -> finite` were used on oo/zoo)
  rule <k> close => #inconsistent </k>
       <facts> rational |-> true finite |-> false _REST </facts>

  // rational=true but real=false
  rule <k> close => #inconsistent </k>
       <facts> rational |-> true real |-> false _REST </facts>

  // integer=true but rational=false
  rule <k> close => #inconsistent </k>
       <facts> integer |-> true rational |-> false _REST </facts>

  // even=true but integer=false
  rule <k> close => #inconsistent </k>
       <facts> even |-> true integer |-> false _REST </facts>

  // infinite=true but finite=true    (would fire under a hypothetical real->finite for oo)
  rule <k> close => #inconsistent </k>
       <facts> infinite |-> true finite |-> true _REST </facts>
endmodule

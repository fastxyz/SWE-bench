// mini_assumptions.k
// =====================================================================
// A "mini-X" K semantics of the FRAGMENT of SymPy's assumption engine
// that the V1 fix touches.  It is NOT a model of SymPy as a whole; it
// models exactly the deduction machinery in:
//
//   * sympy/core/facts.py    : deduce_alpha_implications (consistency
//                              check + contrapositive closure, l.116/126-131),
//                              FactKB._tell (3-valued update + conflict,
//                              l.484-496), FactKB.deduce_all_facts (the
//                              forward-chaining fixpoint loop, l.501-537).
//   * sympy/core/assumptions.py : the _assume_rules slice exercised by the
//                              issue (even/integer/rational/finite/infinite/
//                              real/irrational/noninteger), INCLUDING the V1
//                              addition  'rational -> finite'  (l.175).
//
// MODELING CHOICES (faithfulness notes):
//   - The real engine precomputes a *transitively closed* implication
//     table (full_implications) and fires it; here we encode the *direct*
//     edges and let the <k> activation cascade reach the same closure.
//     Same least fixpoint, smaller artifact.  (deduce_alpha_implications
//     uses Warshall; deduce_all_facts re-drains a worklist — both compute
//     the closure, which is all the spec needs.)
//   - "None"/unknown is modeled by ABSENCE of the key from <kb>.
//     True/False are the two Bool values a present key may hold.
//   - Each alpha edge is added together with its CONTRAPOSITIVE, exactly
//     as facts.py:116 does:  implications + [(Not(j),Not(i)) ...].
//   - We model only the fact slice the claims need ("cover only what the
//     code touches").  Adding the rest is mechanical and changes nothing.
//
// Constructed, not machine-checked (MVP): this file + the run-commands in
// PROOF.md are what a later `kompile`/`kprove` would discharge.
// =====================================================================

module MINI-ASSUMPTIONS-SYNTAX
  imports BOOL-SYNTAX

  // The assumption predicates ("facts") in the exercised slice.
  syntax Fact ::= "integer"  | "rational" | "real"    | "finite"
                | "infinite" | "even"     | "odd"      | "irrational"
                | "noninteger" | "positive" | "complex"

  // A deduction program is a sequence of generator facts to assert,
  // followed by `close` (run the engine to its fixpoint).
  syntax Stmt ::= "tell" "(" Fact "," Bool ")"
                | "close"
                | Stmt Stmt            [left]
endmodule

module MINI-ASSUMPTIONS
  imports MINI-ASSUMPTIONS-SYNTAX
  imports BOOL
  imports MAP
  imports K-EQUAL

  // ----- configuration -------------------------------------------------
  // <k>      : the computation (doubles as the deduce_all_facts worklist;
  //            `~>` is the cons of pending work, `.K` is the empty worklist)
  // <kb>     : the knowledge base, Fact |-> Bool  (absent key == None)
  // <status> : `ok` until a contradiction is told, then `inconsistent`
  //            (models FactKB._tell raising InconsistentAssumptions and
  //             deduce_alpha_implications raising ValueError)
  configuration
    <k> $PGM:Stmt </k>
    <kb> .Map </kb>
    <status> ok </status>

  syntax KItem ::= "activate" "(" Fact "," Bool ")"   // process implications of a just-set fact
                 | "checkBeta"                          // re-scan beta triggers

  // ----- statement sequencing -----------------------------------------
  rule <k> S1:Stmt S2:Stmt => S1 ~> S2 ... </k>
  rule <k> close => checkBeta ... </k>                  // drain, then settle beta rules

  // ----- _tell(F, V)  (facts.py FactKB._tell, l.484-496) --------------
  // (a) new fact: record it and schedule its forward implications
  rule <k> tell(F:Fact, V:Bool) => activate(F, V) ... </k>
       <kb> KB => KB[F <- V] </kb>
    requires notBool (F in_keys(KB))

  // (b) redundant: already known with the same value -> no-op (returns False in code)
  rule <k> tell(F:Fact, V:Bool) => .K ... </k>
       <kb> KB </kb>
    requires (F in_keys(KB)) andBool (KB[F] ==K V)

  // (c) conflict: known with the OPPOSITE value -> InconsistentAssumptions
  rule <k> tell(F:Fact, V:Bool) => .K ... </k>
       <kb> KB </kb>
       <status> _ => inconsistent </status>
    requires (F in_keys(KB)) andBool (KB[F] =/=K V)

  // ----- ALPHA implications (assumptions.py _assume_rules slice) -------
  // Each `activate(F,V)` enqueues `tell(...)` for every DIRECT implication
  // of (F,V).  Both the forward edge and its contrapositive are present,
  // mirroring deduce_alpha_implications (facts.py:116).

  //  even -> integer            /  !integer -> !even
  rule <k> activate(even, true)      => tell(integer, true)  ~> checkBeta ... </k>
  //  odd  -> integer            /  !integer -> !odd
  rule <k> activate(odd, true)       => tell(integer, true)  ~> checkBeta ... </k>
  //  integer -> rational        /  !rational -> !integer
  rule <k> activate(integer, true)   => tell(rational, true) ~> checkBeta ... </k>
  rule <k> activate(rational, false) => tell(integer, false) ~> checkBeta ... </k>
  rule <k> activate(integer, false)  => tell(even, false) ~> tell(odd, false) ~> checkBeta ... </k>
  //  rational -> real           /  !real -> !rational
  rule <k> activate(rational, true)  => tell(real, true) ~> tell(finite, true) ~> checkBeta ... </k>
  //  rational -> finite   <==== THE V1 FIX (assumptions.py:175)
  //                             contrapositive  !finite -> !rational
  rule <k> activate(finite, false)   => tell(rational, false) ~> checkBeta ... </k>
  //  positive -> real           (positive -> nonnegative -> real, shortcut)
  rule <k> activate(positive, true)  => tell(real, true) ~> checkBeta ... </k>
  //  infinite -> !finite        /  finite -> !infinite
  rule <k> activate(infinite, true)  => tell(finite, false) ~> checkBeta ... </k>
  rule <k> activate(finite, true)    => tell(infinite, false) ~> checkBeta ... </k>

  // Facts with no further direct implication in the slice just settle beta.
  rule <k> activate(real, _)       => checkBeta ... </k>
  rule <k> activate(complex, _)    => checkBeta ... </k>
  rule <k> activate(irrational, _) => checkBeta ... </k>
  rule <k> activate(noninteger, _) => checkBeta ... </k>
  rule <k> activate(infinite, false) => checkBeta ... </k>
  rule <k> activate(positive, false) => checkBeta ... </k>
  rule <k> activate(even, false)   => checkBeta ... </k>
  rule <k> activate(odd, false)    => checkBeta ... </k>

  // ----- BETA rules (joined conditions; assumptions.py biconditionals) -
  //  irrational == real & !rational   ==>  beta:  real & !rational -> irrational
  rule <k> checkBeta => tell(irrational, true) ... </k>
       <kb> KB </kb>
    requires (real in_keys(KB)) andBool (KB[real] ==K true)
     andBool (rational in_keys(KB)) andBool (KB[rational] ==K false)
     andBool (notBool (irrational in_keys(KB)))

  //  noninteger == real & !integer    ==>  beta:  real & !integer -> noninteger
  rule <k> checkBeta => tell(noninteger, true) ... </k>
       <kb> KB </kb>
    requires (real in_keys(KB)) andBool (KB[real] ==K true)
     andBool (integer in_keys(KB)) andBool (KB[integer] ==K false)
     andBool (notBool (noninteger in_keys(KB)))

  // no beta fires -> checkBeta is consumed (fixpoint reached for this item)
  rule <k> checkBeta => .K ... </k>  [owise]
endmodule

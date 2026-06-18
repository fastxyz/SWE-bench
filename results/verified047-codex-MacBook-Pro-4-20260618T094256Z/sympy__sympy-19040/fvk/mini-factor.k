module MINI-FACTOR-SYNTAX
  imports INT-SYNTAX
  imports BOOL-SYNTAX

  // Abstract factors used by the audit.  XMINUS1 represents a factor that
  // depends on the main variable.  YMINUS1 represents a factor that is content
  // with respect to the main variable in a two-variable ring.
  syntax Factor ::= "XMINUS1" | "YMINUS1" | "OTHER" Int

  // Factor bags keep multiplicity.  The model assumes well-formed bags:
  // positive multiplicities and no duplicate factor keys between the content
  // and primitive bags.  Those helper obligations are recorded in
  // dmp-ext-factor-obligations.k.
  syntax FBag ::= ".FBag"
                | Factor ":" Int ";" FBag [right]

  syntax Cand ::= ".Cand"
                | Factor ";" Cand [right]

  // poly(LC, CC, CONT, PRIM)
  // LC is the ground leading coefficient captured before monic normalization.
  // CC is the scalar coefficient returned when factoring the main-variable
  // content.  CONT is the lower-variable content factor bag.  PRIM is the
  // primitive-part factor bag recoverable by the square-free norm path.
  syntax PVal ::= "poly" "(" Int "," Int "," FBag "," FBag ")"

  syntax Factored ::= "factored" "(" Int "," FBag ")"

  syntax Exp ::= PVal
               | Factored
               | FBag
               | Cand
               | Bool
               | "dmpExtFactor" "(" PVal ")"
               | "legacyExtFactor" "(" PVal ")"
               | "trial" "(" PVal "," Cand ")"

  syntax KResult ::= PVal | Factored | FBag | Cand | Int | Bool
endmodule

module MINI-FACTOR
  imports MINI-FACTOR-SYNTAX
  imports INT
  imports BOOL

  configuration <k> $PGM:Exp </k>

  syntax Bool ::= "wfPoly" "(" PVal ")" [function]
  syntax Bool ::= "primitiveSplitOk" "(" PVal ")" [function]
  syntax Bool ::= "normComplete" "(" FBag ")" [function]
  syntax Bool ::= "inCand" "(" Factor "," Cand ")" [function]
  syntax Cand ::= "append" "(" Cand "," Cand ")" [function]
  syntax Cand ::= "contentCandidates" "(" FBag ")" [function]
  syntax Cand ::= "primitiveCandidates" "(" FBag ")" [function]
  syntax FBag ::= "bagUnion" "(" FBag "," FBag ")" [function]
  syntax FBag ::= "restrict" "(" FBag "," Cand ")" [function]

  rule append(.Cand, C) => C
  rule append(F ; C1, C2) => F ; append(C1, C2)

  rule contentCandidates(.FBag) => .Cand
  rule contentCandidates(F : N ; REST) => F ; contentCandidates(REST)
    requires N >Int 0

  rule primitiveCandidates(.FBag) => .Cand
  rule primitiveCandidates(F : N ; REST) => F ; primitiveCandidates(REST)
    requires N >Int 0

  rule bagUnion(.FBag, B) => B
  rule bagUnion(F : N ; B1, B2) => F : N ; bagUnion(B1, B2)

  rule inCand(F, .Cand) => false
  rule inCand(F, F ; REST) => true
  rule inCand(F, G ; REST) => inCand(F, REST)
    requires F =/=K G

  rule restrict(.FBag, C) => .FBag
  rule restrict(F : N ; REST, C) => F : N ; restrict(REST, C)
    requires N >Int 0 andBool inCand(F, C)
  rule restrict(F : N ; REST, C) => restrict(REST, C)
    requires N >Int 0 andBool notBool inCand(F, C)

  // V1 behavior: factor main-variable content first, lift those content
  // factors, then append primitive factors produced by the norm path.  Trial
  // division is modeled by restricting the original factor bag to the candidate
  // set while preserving original multiplicities.
  rule <k> dmpExtFactor(poly(LC, CC, CONT, PRIM))
        => factored(LC *Int CC,
                    restrict(bagUnion(CONT, PRIM),
                             append(contentCandidates(CONT),
                                    primitiveCandidates(PRIM))))
        ... </k>

  rule <k> trial(poly(LC, CC, CONT, PRIM), C)
        => factored(LC *Int CC,
                    restrict(bagUnion(CONT, PRIM), C))
        ... </k>

  // Diagnostic model of pre-V1 behavior: candidates came only from the norm
  // path after main-variable content had already been removed.
  rule <k> legacyExtFactor(poly(LC, CC, CONT, PRIM))
        => factored(LC,
                    restrict(bagUnion(CONT, PRIM),
                             primitiveCandidates(PRIM)))
        ... </k>
endmodule

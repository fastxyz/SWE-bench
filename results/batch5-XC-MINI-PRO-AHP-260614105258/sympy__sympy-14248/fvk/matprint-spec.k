// Reachability claims for the matrix-printer fragment.
// CONSTRUCTED, NOT MACHINE-CHECKED.
requires "matprint.k"

module MATPRINT-SPEC-SYNTAX
  imports MATPRINT-SYNTAX
endmodule

module VERIFICATION
  imports MATPRINT-SPEC-SYNTAX
  imports MATPRINT
  imports K-EQUAL

  // ---- spec-only abstraction functions (vocabulary for the postconditions) ---
  // render(SS) = the intended, correctly-signed concatenation of term-strings.
  // This is the closed form _print_MatAdd is specified to produce.
  syntax String ::= render(Strings)        [function]
                  | renderTail(Strings)    [function]   // ' '.join over [body0,sg1,body1,...]
                  | sgOf(String)           [function]
                  | bodyOf(String)         [function]

  rule sgOf(S)   => "-"      requires isNeg(S)
  rule sgOf(S)   => "+"      requires notBool isNeg(S)
  rule bodyOf(S) => tail(S)  requires isNeg(S)
  rule bodyOf(S) => S        requires notBool isNeg(S)

  rule render(.Strings) => ""                              // empty: see FINDING F2
  rule render(S:String, SS:Strings) => #head(sgOf(S)) +String renderTail(S, SS)

  rule renderTail(S:String, .Strings) => bodyOf(S)
  rule renderTail(S:String, S2:String, SS:Strings)
       => bodyOf(S) +String " " +String sgOf(S2) +String " " +String renderTail(S2, SS)

  // wf(SS): well-formedness — the bug-fix property.  No term is rendered as
  // "+ -...".  Equivalent: every non-leading negative term is introduced by a
  // "-" separator, never "+".  This is what render() guarantees by construction
  // and what the proof shows _print_MatAdd computes.
endmodule

module MATPRINT-SPEC
  imports VERIFICATION

  // (MATADD) Function contract for str/latex _print_MatAdd.
  // SPEC-PROVENANCE:
  // - from_prompt: "differences like a-b ... are supposed to print like a-b" =>
  //     each negative term must be joined with '-', never '+ (-1)*'.
  // - from_code: the for-loop strips a leading '-' and uses it as the term sign.
  // - obligation: printMatAdd(SS) terminates with res = render(SS) for n>=1.
  claim <k> printMatAdd(SS:Strings) => .K </k>
        <terms> _ => .List </terms>
        <l> _ => .List </l>
        <res> _ => render(SS) </res>
    requires SS =/=K .Strings           // n >= 1 (FINDING F2: empty excluded)
    [all-path]

  // (LOOP) Circularity for the term loop, generalised over the already-built
  // working list LACC and the remaining terms.  Running #loop from any partial
  // state appends, for each remaining term S, the pair [sgOf(S), bodyOf(S)].
  // SPEC-PROVENANCE:
  // - from_code: l.extend([sign, t]) per iteration; sign/t per startswith('-').
  // - soundness: holds for ALL LACC and ALL term lists (no side condition needed
  //     beyond the list being finite — the loop is structural over <terms>).
  claim <k> #loop => #assemble </k>
        <terms> TS:List => .List </terms>
        <l> LACC:List => LACC appendPairs(TS) </l>
    [all-path]

  // appendPairs(TS): the tokens the loop appends for the remaining terms TS.
  syntax List ::= appendPairs(List) [function]
  rule appendPairs(.List) => .List
  rule appendPairs(ListItem(S:String) TS:List)
       => ListItem(sgOf(S)) ListItem(bodyOf(S)) appendPairs(TS)

  // (MATMUL) Function contract + TOTALITY for str _print_MatMul's sign fold.
  // SPEC-PROVENANCE:
  // - from_prompt: a-b must not print "(-1)*b"; a negative numeric coeff -> "-".
  // - from_code(V2): guard `c.is_number and c.is_negative`.
  // - FINDING F1: this claim's `nonreal` instance is the one V1 (`c < 0`) FAILS:
  //     V1 has no rule for printMatMul(nonreal, _) (the guard raises), so the
  //     computation is stuck — the totality obligation is violated by V1, met by V2.
  claim <k> printMatMul(neg, BODY:String) => "-" +String BODY </k>     [all-path]
  claim <k> printMatMul(nonneg, BODY:String) => BODY </k>             [all-path]
  claim <k> printMatMul(nonreal, BODY:String) => BODY </k>            [all-path] // V2 only
  claim <k> printMatMul(sym, BODY:String) => BODY </k>                [all-path]

  // map/extensionality-style simplification not needed: postconditions are plain
  // String equalities discharged by STRING + the render/joinSp definitions.
endmodule

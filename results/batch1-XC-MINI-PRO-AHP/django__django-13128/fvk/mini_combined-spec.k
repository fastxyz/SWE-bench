// mini_combined-spec.k
// =====================================================================
// Reachability claims for the V1 fix
//   CombinedExpression._resolve_output_field  (the `resolve` program of
//   mini_combined.k).
//
// Three claims fully characterise the method:
//   (FIX-TEMPORAL)  on the temporal-subtraction set it returns DurationField;
//   (DEFER)         on EVERY other input it returns exactly baseVal(L,R), the
//                   UNCHANGED base result  ==> regression-freedom.
// Plus a functional-equality lemma (CONSISTENCY) tying the fix's dispatch
// predicate to the one `as_sql` (lines 460-462) uses, so type inference and
// SQL generation can never disagree about which expressions are temporal
// subtractions.
//
// Constructed, NOT machine-checked.
// =====================================================================

requires "mini_combined.k"

module MINI-COMBINED-SPEC-SYNTAX
  imports MINI-COMBINED-SYNTAX
endmodule

module VERIFICATION
  imports MINI-COMBINED-SPEC-SYNTAX
  imports MINI-COMBINED
  imports K-EQUAL

  // ---- as_sql's temporal-subtraction dispatch predicate (lines 460-462) ----
  // lhs_type/rhs_type are get_internal_type() with `except FieldError: None`;
  // on the modelled input domain (no `mixed` inputs) that maps a `none`
  // source to None and a concrete source to its type.  The test is then
  //   `connector == SUB and lhs_type in datetime_fields and lhs_type == rhs_type`.
  //   * `lhs_type in datetime_fields`  ==  nnTemporal(L)   (None -> false)
  //   * `lhs_type == rhs_type`         ==  L ==K R         (none models None)
  syntax Bool ::= nnTemporal(Field)             [function, total]
  rule nnTemporal(none)    => false
  rule nnTemporal(F:Field) => isTemporal(F)     requires F =/=K none

  syntax Bool ::= asSqlTempSub(Conn, Field, Field) [function, total]
  rule asSqlTempSub(C:Conn, L:Field, R:Field)
    => C ==K SUB andBool nnTemporal(L) andBool (L ==K R)
endmodule

module MINI-COMBINED-SPEC
  imports VERIFICATION

  // (FIX-TEMPORAL)  connector == SUB and both sources are the SAME temporal
  // type  =>  the inferred output field is DurationField.
  // This is the whole point of the fix: pre-fix the result was baseVal(T,T)=T
  // (e.g. DateTimeField); post-fix it is DurationField.
  claim <k> resolve => .K </k>
        <conn> SUB </conn>
        <lhs> T:Field </lhs>
        <rhs> T:Field </rhs>
        <out> _ => DurationField </out>
    requires isTemporal(T)
    [all-path]

  // (DEFER)  On EVERY input that is NOT a temporal subtraction, the method
  // returns exactly baseVal(L,R) -- the result of the UNCHANGED base method.
  // Covers: every non-SUB connector; SUB with a None source; SUB with
  // differing types; SUB with same NON-temporal type (e.g. Duration-Duration,
  // Integer-Integer).  ==> the fix changes behaviour on NOTHING outside the
  // temporal-subtraction set.
  claim <k> resolve => .K </k>
        <conn> C:Conn </conn>
        <lhs> L:Field </lhs>
        <rhs> R:Field </rhs>
        <out> _ => baseVal(L, R) </out>
    requires notBool isTempSub(C, L, R)
    [all-path]

  // (CONSISTENCY)  The fix's dispatch predicate equals as_sql's, for all
  // inputs -- so _resolve_output_field and as_sql always agree on which
  // CombinedExpressions are temporal subtractions.  Pure first-order fact
  // over a finite domain (Conn x Field x Field); discharged by case analysis
  // / Z3 (see PROOF.md PO4).  Stated here as the simplification it reduces to:
  //
  //   isTempSub(C,L,R)  ==Bool  asSqlTempSub(C,L,R)        for all C,L,R
  //
  // Key step: (L =/= none) andBool (L ==K R)  implies  (R =/= none), so the
  // extra `rhs is not None` conjunct in isTempSub is redundant, leaving the
  // two predicates syntactically equal.
  rule isTempSub(C:Conn, L:Field, R:Field)
    => asSqlTempSub(C, L, R)                                 [simplification]
endmodule

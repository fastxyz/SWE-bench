// constraints-spec.k — reachability claims for the django__django-16560 V1 fix.
//
// These claims formalize the contracts in fvk/SPEC.md. All are loop-free and
// recursion-free, so they are discharged by Reflexivity / Axiom / Transitivity /
// Case-Analysis / Consequence ONLY — no Circularity rule is required (see PROOF.md).
//
// Convention: uppercase logical variables (C, M, ...) are symbolic; `vec` is the
// program identifier for `violation_error_code`.

requires "constraints.k"

module CONSTRAINTS-SPEC-SYNTAX
  imports CONSTRAINTS-SYNTAX
endmodule

module VERIFICATION
  imports CONSTRAINTS-SPEC-SYNTAX
  imports CONSTRAINTS
  imports MAP-SYMBOLIC
  imports K-EQUAL
endmodule

module CONSTRAINTS-SPEC
  imports VERIFICATION

  // (INIT-CODE) BaseConstraint.__init__ code-assignment slice:
  //     if violation_error_code is not None: self.violation_error_code = violation_error_code
  // Modeled with the argument bound in <kwargs> as key "vec" = C (kwget reads it).
  // Postcondition: the EFFECTIVE attribute value (instance attr if set, else class
  // default null) equals C, for EVERY C including null.
  claim
    <k> if kwget("vec") isNotNull : self . vec = kwget("vec") ;
        ~> self . vec               // observe the effective value
        => C:Val ... </k>
    <self> .Map </self>
    <kwargs> "vec" |-> C:Val </kwargs>
    [all-path]

  // (DECON-CODE) BaseConstraint.deconstruct() code-emission slice:
  //     if self.violation_error_code is not None: kwargs["violation_error_code"] = self.violation_error_code
  // Postcondition: reading kwargs with default None yields C, for EVERY C.
  claim
    <k> if self . vec isNotNull : kwput("vec", self . vec) ;
        ~> kwget("vec")            // observe deconstructed value, default None
        => C:Val ... </k>
    <self> vec |-> C:Val </self>
    <kwargs> .Map </kwargs>
    [all-path]

  // (ROUNDTRIP-CODE) clone == deconstruct then __init__ preserves the code.
  // Compose DECON-CODE (build kwargs from self.vec = C) with INIT-CODE (build a
  // fresh self.vec from those kwargs). Final effective code on the fresh object = C.
  claim
    <k> if self . vec isNotNull : kwput("vec", self . vec) ;       // deconstruct
        if kwget("vec") isNotNull : self . vec = kwget("vec") ;    // __init__(**kwargs) (fresh self)
        ~> self . vec
        => C:Val ... </k>
    <self> vec |-> C:Val => ?_:Map </self>
    <kwargs> .Map => ?_:Map </kwargs>
    [all-path]

  // (VALIDATE-CODE) validate() in-domain raise (CheckConstraint / ExclusionConstraint
  //  / UniqueConstraint expressions+condition branches): on violation, the recorded
  //  error carries code == effective violation_error_code == C, for EVERY C.
  //  M is the (already-computed) violation message.
  claim
    <k> raiseErr ( M:Val , self . vec ) ; => .K </k>
    <self> vec |-> C:Val </self>
    <error> null => errpair(M:Val, C:Val) </error>
    [all-path]

  // (EQ-CODE) __eq__ includes violation_error_code: two records that differ only in
  //  the code are NOT equal. (C1 =/= C2  =>  (... === ...) reduces to false.)
  claim
    <k> ( self . vec ) === C2:Val => false ... </k>
    <self> vec |-> C1:Val </self>
    requires C1 =/=K C2
    [all-path]
endmodule

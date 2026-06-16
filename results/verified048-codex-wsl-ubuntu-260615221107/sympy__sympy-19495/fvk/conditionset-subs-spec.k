// K claims for the audited ConditionSet._eval_subs branch.
// Constructed, not machine-checked.

requires "mini-sympy-substitution.k"

module CONDITIONSET-SUBS-SPEC
  imports MINI-SYMPY-SUBSTITUTION

  // SPEC-PROVENANCE:
  // - from_prompt: non-simultaneous subs through ConditionSet/ImageSet should
  //   produce the same substituted ImageSet as xreplace/simultaneous subs.
  // - from_code: V1 adds the dummy-independence guard before returning base.
  claim
    <k> EvalSubs(SYM, COND, BASE, OLD, NEW)
      => subSet(BASE, OLD, NEW) ... </k>
    requires oldIsSym(OLD, SYM) ==Bool false
     andBool subCond(COND, OLD, NEW) ==K TrueCond
     andBool dependsOn(SYM, COND) ==Bool false
    [all-path]

  // SPEC-PROVENANCE:
  // - from_public_test: dummy-dependent true conditions caused by assumptions
  //   preserve the legacy membership-fallback behavior.
  // - from_code: V1 leaves this branch unchanged.
  claim
    <k> EvalSubs(SYM, COND, BASE, OLD, NEW)
      => ConditionSetValueObj(NEW,
           ContainsCond(NEW, subSet(BASE, OLD, NEW)),
           subSet(BASE, OLD, NEW)) ... </k>
    requires oldIsSym(OLD, SYM) ==Bool false
     andBool subCond(COND, OLD, NEW) ==K TrueCond
     andBool dependsOn(SYM, COND) ==Bool true
    [all-path]

  // SPEC-PROVENANCE:
  // - from_code: the non-true branch is outside the bug and remains the
  //   existing constructor-mediated result.
  claim
    <k> EvalSubs(SYM, COND, BASE, OLD, NEW)
      => ConditionSetObj(SYM,
           subCond(COND, OLD, NEW),
           subSet(BASE, OLD, NEW)) ... </k>
    requires oldIsSym(OLD, SYM) ==Bool false
     andBool notBool (subCond(COND, OLD, NEW) ==K TrueCond)
    [all-path]
endmodule


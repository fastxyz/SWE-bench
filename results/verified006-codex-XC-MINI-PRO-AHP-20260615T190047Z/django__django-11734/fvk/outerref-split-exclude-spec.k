requires "mini-orm-scope.k"

module OUTERREF-SPLIT-EXCLUDE-SPEC
  imports MINI-ORM-SCOPE

  // SPEC-PROVENANCE:
  // - from_prompt: "OuterRef in exclude() or ~Q() uses wrong model."
  // - from_prompt: "OuterRef resolves to "V0"."id" instead of "queries_number"."id""
  // - from_code: split_exclude() now wraps an existing OuterRef as OuterRef(filter_rhs).
  claim
    <k> pipeline(OuterRef(FRef("pk")), 0, 1, 2) => Bound(2, "pk") </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_code: plain F() references were already shifted by split_exclude().
  // - from_intent: preserve behavior outside the reported OuterRef bug.
  claim
    <k> pipeline(FRef("local_field"), 0, 1, 2) => Bound(1, "local_field") </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_intent: values that are not F()/OuterRef() are outside the scope shift.
  claim
    <k> pipeline(Literal("rhs"), 0, 1, 2) => Literal("rhs") </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: public hint identifies the wrong immediate-parent alias.
  // - from_code: this models the pre-V1 generic F branch for OuterRef.
  claim
    <k> pipelineV0(OuterRef(FRef("pk")), 0, 1, 2) => Bound(1, "pk") </k>
    [all-path]
endmodule


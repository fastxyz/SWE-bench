requires "mini-xor-fallback.k"

module XOR-FALLBACK-SPEC
  imports MINI-XOR-FALLBACK

  // SPEC-PROVENANCE:
  // - from_prompt: "a ^ b ^ c is true when an odd number of the arguments are true"
  //   => fallback must implement odd truth-count parity.
  // - from_code: V1 renders (OR children) AND ((CASE-sum mod 2) == 1).
  // - from_domain: ORM-produced XOR child lists are non-empty.
  claim <k> fallback(BS:BList) => oddParity(BS) </k>
    requires nonEmpty(BS) ==Bool true
    [all-path]

  // SPEC-PROVENANCE:
  // - from_code: WhereNode.as_sql() applies self.negated to the synthesized node.
  // - from_prompt: negation of XOR should negate the same parity predicate.
  claim <k> negFallback(BS:BList) => notBool oddParity(BS) </k>
    requires nonEmpty(BS) ==Bool true
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: the reported bug is exactly-one semantics for three true
  //   operands; this claim records the counterexample to the pre-fix rule.
  claim <k> exactlyOne(true , true , true , .BList) => false </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: the corrected interpretation makes three true operands true.
  claim <k> oddParity(true , true , true , .BList) => true </k>
    [all-path]
endmodule

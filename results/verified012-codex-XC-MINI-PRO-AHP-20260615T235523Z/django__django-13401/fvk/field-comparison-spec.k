requires "mini-field-comparison.k"

module FIELD-COMPARISON-SPEC
  imports MINI-FIELD-COMPARISON

  // SPEC-PROVENANCE:
  // - from_prompt: "if the field.model is different, they will compare unequal"
  //   => same counter plus different owner model must yield false equality.
  claim <k>
    fieldEq(Field(C, Model(L1, I1)), Field(C, Model(L2, I2))) => false
  </k>
  requires notBool sameModel(Model(L1, I1), Model(L2, I2))

  // SPEC-PROVENANCE:
  // - from_prompt: "adjust __hash__ ... to match"
  //   => equal fields must have equal hash keys.
  claim <k>
    sameHashKey(Field(C, M), Field(C, M)) => true
  </k>

  // SPEC-PROVENANCE:
  // - from_prompt: set reproduction should retain both B.myfield and C.myfield.
  //   => different owner model keys keep both entries.
  claim <k>
    setKeepsBoth(Field(C, Model("app.b", IB)), Field(C, Model("app.c", IC))) => true
  </k>

  // SPEC-PROVENANCE:
  // - from_prompt: "order first by self.creation_counter"
  //   => different counters ignore model order.
  claim <k>
    fieldLt(Field(C1, M1), Field(C2, M2)) => C1 <Int C2
  </k>
  requires C1 =/=Int C2

  // SPEC-PROVENANCE:
  // - from_prompt: "__lt__ ... to match" equality collision handling.
  // - from_code: V1 tie-breaks same-counter fields with model label and identity.
  //   => equal-counter different labels order by label.
  claim <k>
    fieldLt(Field(C, Model(L1, I1)), Field(C, Model(L2, I2))) => true
  </k>
  requires L1 <String L2
endmodule

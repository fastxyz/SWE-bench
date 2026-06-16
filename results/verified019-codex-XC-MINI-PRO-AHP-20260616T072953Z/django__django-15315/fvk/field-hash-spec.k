requires "mini-field-hash.k"

module FIELD-HASH-SPEC
  imports MINI-FIELD-HASH
  imports INT
  imports BOOL
  imports K-EQUAL

  // SPEC-PROVENANCE:
  // - from_prompt: "Field.__hash__ changes value when a field is assigned to a model class."
  //   => attaching a model must not change the hash of the same Field instance.
  // - from_prompt: "Objects with the same hash are still checked for equality"
  //   => unequal fields are allowed to share a hash value.
  // - from_code: Field.__init__ assigns creation_counter; contribute_to_class mutates model.
  claim
    <k> hash(attach(field(C:Int, noModel), model(M:Int))) => C ... </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_default_domain: Python hash/equality contract requires equal objects to have equal hashes.
  // - from_code: Field.__eq__ returns true only when creation_counter and model match.
  claim
    <k> hash(field(C:Int, M:ModelKey)) => C ... </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_code: Field.__eq__ compares both creation_counter and model.
  claim
    <k> eq(field(C:Int, M:ModelKey), field(C:Int, M:ModelKey)) => true ... </k>
    [all-path]
endmodule

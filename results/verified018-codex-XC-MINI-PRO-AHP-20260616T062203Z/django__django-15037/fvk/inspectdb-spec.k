requires "fvk/mini-inspectdb.k"

module INSPECTDB-SPEC
  imports MINI-INSPECTDB

  // SPEC-PROVENANCE:
  // - from_prompt: "FOREIGN KEY(other_id) references foo(other_id)" =>
  //   non-primary-key relation targets must be preserved with to_field.
  // - from_docs: ForeignKey.to_field names the related object field and is
  //   needed when the relation targets a field other than the primary key.
  claim
    <k> relationExtraParams(RelColumn:String, TargetPk:String, TargetField:String)
        => "to_field" |-> TargetField
    </k>
    requires RelColumn =/=String TargetPk
    [all-path]

  // SPEC-PROVENANCE:
  // - from_docs: ForeignKey targets the related object primary key by default.
  // - from_compatibility: preserve normal primary-key foreign key output.
  claim
    <k> relationExtraParams(TargetPk:String, TargetPk:String, TargetField:String)
        => .Map
    </k>
    [all-path]
endmodule

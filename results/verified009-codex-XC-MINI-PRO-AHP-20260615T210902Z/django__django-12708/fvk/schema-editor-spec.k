requires "mini-schema.k"

module SCHEMA-EDITOR-SPEC
  imports MINI-SCHEMA

  // SPEC-PROVENANCE:
  // - from_prompt: "will find two constraints, the _uniq and the _idx one"
  //   => index-only filtering selects both same-column objects.
  // - from_code: V0 means the old alter_index_together() call with only
  //   {'index': True}.
  claim
    <k> deleteIndexTogetherV0(
          "a,b",
          constraint("_uniq", "a,b", true, true, false)
          ; constraint("_idx", "a,b", true, false, false)
          ; .Constraints
        )
        => wrongCount("_uniq" , "_idx" , .Names) </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: "The deletion of index_together should be possible alone
  //   or made coherent ... with unique_together"
  //   => delete the non-unique index, not the same-column unique object.
  // - from_code: index_together creation uses _create_index_sql(... "_idx"),
  //   so the intended object has unique=false.
  claim
    <k> deleteIndexTogetherV1(
          "a,b",
          constraint("_uniq", "a,b", true, true, false)
          ; constraint("_idx", "a,b", true, false, false)
          ; .Constraints
        )
        => deleted("_idx") </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_intent_audit: no ordered result is stated by public intent.
  //   This mirrored claim prevents the proof from depending on list order.
  claim
    <k> deleteIndexTogetherV1(
          "a,b",
          constraint("_idx", "a,b", true, false, false)
          ; constraint("_uniq", "a,b", true, true, false)
          ; .Constraints
        )
        => deleted("_idx") </k>
    [all-path]
endmodule

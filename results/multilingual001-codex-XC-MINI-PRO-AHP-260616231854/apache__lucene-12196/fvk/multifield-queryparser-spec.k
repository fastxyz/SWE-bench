requires "mini-queryparser.k"

module MULTIFIELD-QUERYPARSER-SPEC
  imports MINI-QUERYPARSER

  // SPEC-PROVENANCE:
  // - from_prompt: "when I don't pass boosts ... slop is working as expected" => direct phrase slop remains supported.
  // - from_code: existing helper handles PhraseQuery.
  claim <k> applySlop(phrase(P:String, OLD:Int), S:Int)
        => phrase(P, S) </k>
        [all-path]

  // SPEC-PROVENANCE:
  // - from_code: existing helper handles MultiPhraseQuery with the same slop-setting intent.
  claim <k> applySlop(multiPhrase(P:String, OLD:Int), S:Int)
        => multiPhrase(P, S) </k>
        [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: "Output is field1:\"hello world\"~1^1.5" => phrase slop and boost both appear.
  // - from_prompt: "slop is missing from output" => preserving boost alone is insufficient.
  // - from_hint: "BoostQuery is not handled in setSlop function" => BoostQuery wrapper must be transparent to slop application.
  claim <k> applySlop(boost(phrase(P:String, OLD:Int), B:String), S:Int)
        => boost(phrase(P, S), B) </k>
        [all-path]

  // SPEC-PROVENANCE:
  // - from_code: existing helper handles MultiPhraseQuery with the same slop-setting intent.
  // - from_hint: BoostQuery wrapper transparency applies to any query shape the helper already supports.
  claim <k> applySlop(boost(multiPhrase(P:String, OLD:Int), B:String), S:Int)
        => boost(multiPhrase(P, S), B) </k>
        [all-path]

  // SPEC-PROVENANCE:
  // - from_code: non-phrase queries are not modified by applySlop.
  // - frame condition: adding BoostQuery handling must preserve non-phrase wrapped queries and their boost.
  claim <k> applySlop(boost(other(P:String), B:String), S:Int)
        => boost(other(P), B) </k>
        [all-path]

  // SPEC-PROVENANCE:
  // - from_code: applySlop is null-tolerant through instanceof checks.
  // - frame condition: adding BoostQuery handling must preserve null query behavior.
  claim <k> applySlop(nullQuery, S:Int) => nullQuery </k>
        [all-path]
endmodule

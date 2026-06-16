requires "mini-python-autodoc.k"

module AUTODOC-TYPEHINTS-SPEC
  imports MINI-PYTHON-AUTODOC
  imports MAP
  imports STRING
  imports BOOL

  // SPEC-PROVENANCE:
  // - from_prompt: "Expected behavior: types.JSONObject instead of Dict[str, Any] in both cases."
  // - from_docs: autodoc_type_aliases maps type names to fully qualified object names.
  // - from_code: V1 passes app.config.autodoc_type_aliases to inspect.signature().
  claim
    <k> recordTypehints("types.sphinx_doc",
                        "data" |-> "JSONObject" "return" |-> "JSONObject",
                        "JSONObject" |-> "types.JSONObject") => .K </k>
    <annotations>
      .Map
      =>
      "types.sphinx_doc" |-> ("data" |-> "types.JSONObject"
                              "return" |-> "types.JSONObject")
    </annotations>
    [label(CLAIM_RECORD_ALIASED_ANNOTATIONS), all-path]

  // SPEC-PROVENANCE:
  // - from_code: merge_typehints/modify_field_list insert stored strings.
  claim
    <k> mergeTypehints("types.sphinx_doc",
                       "data" |-> "types.JSONObject" "return" |-> "types.JSONObject",
                       .Map) => .K </k>
    <fields>
      .Map
      =>
      "types.sphinx_doc" |-> ("type data" |-> "types.JSONObject"
                              "rtype" |-> "types.JSONObject")
    </fields>
    [label(CLAIM_MERGE_PRESERVES_RECORDED_ALIASES), all-path]

  // SPEC-PROVENANCE:
  // - from_issue: the Dict[str, Any] output is the rejected legacy symptom.
  claim
    <k> recordTypehintsPreFix("types.sphinx_doc",
                              "data" |-> "JSONObject" "return" |-> "JSONObject")
        => .K </k>
    <annotations>
      .Map
      =>
      "types.sphinx_doc" |-> ("data" |-> "Dict[str, Any]"
                              "return" |-> "Dict[str, Any]")
    </annotations>
    [label(CLAIM_PREFIX_FAILS_ALIASED_ANNOTATIONS), all-path]

  // SPEC-PROVENANCE:
  // - from_code: modify_field_list does not add generated type/rtype fields that already exist.
  claim
    <k> mergeTypehints("types.sphinx_doc",
                       "data" |-> "types.JSONObject" "return" |-> "types.JSONObject",
                       "type data" |-> "UserType" "rtype" |-> "UserReturn") => .K </k>
    <fields>
      .Map
      =>
      "types.sphinx_doc" |-> ("type data" |-> "UserType"
                              "rtype" |-> "UserReturn")
    </fields>
    [label(CLAIM_NO_DUPLICATE_USER_FIELDS), all-path]
endmodule

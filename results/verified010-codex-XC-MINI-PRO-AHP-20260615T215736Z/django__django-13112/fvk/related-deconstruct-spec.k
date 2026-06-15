requires "mini-python.k"

module RELATED-DECONSTRUCT-VERIFICATION
  imports MINI-PYTHON
  imports STRING

  rule lowerModelName("Category") => "category" [simplification]
  rule lowerModelName("DJ_RegLogin") => "dj_reglogin" [simplification]
endmodule

module RELATED-DECONSTRUCT-SPEC
  imports RELATED-DECONSTRUCT-VERIFICATION

  // SPEC-PROVENANCE:
  // - from_prompt: mixed-case installed app "DJ_RegLogin" must not become "dj_reglogin".
  // - from_source: make_model_tuple() returns (app_label, model_name.lower()).
  // - from_source: Apps.get_model() treats model names as case-insensitive, not app labels.
  // CLAIM-ID: LAZY-REF-PRESERVES-APP-LABEL
  claim
    <k> serialize(lazyRef(APP:String, MODEL:String))
      => toRef(APP, lowerModelName(MODEL)) </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: concrete reported relation Category in app DJ_RegLogin.
  // CLAIM-ID: REPORTED-CASE
  claim
    <k> serialize(lazyRef("DJ_RegLogin", "Category"))
      => toRef("DJ_RegLogin", "category") </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_finding: legacy whole-string lowercasing reproduces the reported bad app label.
  // CLAIM-ID: LEGACY-REPORTED-CASE
  claim
    <k> legacySerialize(lazyRef("DJ_RegLogin", "Category"))
      => toRef("dj_reglogin", "category") </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_source: Options.label_lower returns app_label plus lowercase model_name.
  // CLAIM-ID: CONCRETE-REF-LABEL-LOWER
  claim
    <k> serialize(concreteRef(APP:String, MODEL_LOWER:String))
      => toRef(APP, MODEL_LOWER) </k>
    [all-path]
endmodule

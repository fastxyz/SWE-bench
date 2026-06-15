module MODEL-ORDERING-SPEC
  imports MINI-DJANGO-ORDERING

  // CLAIM: RELATED-PK-OK
  // SPEC-PROVENANCE:
  // - from_prompt: "Meta.ordering contains __pk of a related field" is valid.
  // - from_code: Query.names_to_path() rewrites pk to opts.pk.name in model context.
  claim <k> checkPath("option__pk",
          ListItem("option") ListItem("pk"),
          "Child",
          none,
          MODELS)
        => ok ... </k>
    requires MODELS["Child.pk"] ==K "id"
     andBool MODELS["Child.option"] ==K relation("Option", .Set)
     andBool MODELS["Option.pk"] ==K "id"
     andBool MODELS["Option.id"] ==K scalar(.Set)

  // CLAIM: RELATED-MISSING-E015
  // SPEC-PROVENANCE:
  // - from_prompt: only valid related __pk should stop raising E015.
  // - from_existing_contract: missing related fields still raise models.E015.
  claim <k> checkPath("option__missing",
          ListItem("option") ListItem("missing"),
          "Child",
          none,
          MODELS)
        => e015("option__missing") ... </k>
    requires MODELS["Child.option"] ==K relation("Option", .Set)
     andBool notBool ("missing" in .Set)

  // CLAIM: SCALAR-PK-E015
  // SPEC-PROVENANCE:
  // - from_code: after a scalar field, remaining parts are transforms, not model aliases.
  // - finding F2: V1 incorrectly rewrote this pk to the model primary key.
  claim <k> checkPath("test__pk",
          ListItem("test") ListItem("pk"),
          "Model",
          none,
          MODELS)
        => e015("test__pk") ... </k>
    requires MODELS["Model.pk"] ==K "id"
     andBool MODELS["Model.id"] ==K scalar(.Set)
     andBool MODELS["Model.test"] ==K scalar(.Set)
     andBool notBool ("pk" in .Set)

  // CLAIM: SCALAR-TRANSFORM-OK
  // SPEC-PROVENANCE:
  // - from_public_tests/source: registered transforms in ordering are valid.
  claim <k> checkPath("test__lower",
          ListItem("test") ListItem("lower"),
          "Model",
          none,
          MODELS)
        => ok ... </k>
    requires MODELS["Model.test"] ==K scalar(SetItem("lower"))

  // CLAIM: FRAME-COMPAT
  // SPEC-PROVENANCE:
  // - from_compatibility_audit: no public signature or error-shape changes.
  // Frame compatibility is discharged in PROOF.md by source-diff locality.
endmodule

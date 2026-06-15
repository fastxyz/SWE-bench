requires "mini-model-form.k"

module CONSTRUCT-INSTANCE-SPEC-SYNTAX
  imports MINI-MODEL-FORM-SYNTAX
endmodule

module CONSTRUCT-INSTANCE-VERIFICATION
  imports MINI-MODEL-FORM
  imports CONSTRUCT-INSTANCE-SPEC-SYNTAX
endmodule

module CONSTRUCT-INSTANCE-SPEC
  imports CONSTRUCT-INSTANCE-VERIFICATION

  // SPEC-PROVENANCE:
  // - from_prompt: "Allow cleaned_data to overwrite fields' default values."
  // - from_prompt: omitted payload may contain a value "derived from another field".
  // - from_tests: omitted empty values preserve defaults; this claim uses cleanedEmpty=false.
  // Claim CI-DERIVED-NONEMPTY-ASSIGNS
  claim
    <k> decide(field(some_field, true, false, true, true, false, true, true, false, false, nonEmpty))
        => assign(some_field, nonEmpty) ... </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: same overwrite obligation as above.
  // - from_code: file fields are deferred through file_field_list.
  // Claim CI-DERIVED-FILE-QUEUES
  claim
    <k> decide(field(file_field, true, false, true, true, false, true, true, false, true, nonEmpty))
        => queueFile(file_field, nonEmpty) ... </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_public_tests: "Empty data uses the model field default."
  // - from_code: empty values are represented by form_field.empty_values.
  // Claim CI-OMITTED-EMPTY-PRESERVES-DEFAULT
  claim
    <k> decide(field(mode, true, false, true, true, false, true, true, true, false, empty))
        => skip ... </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_public_tests: "Blank data doesn't use the model field default."
  // - from_widgets: omittedFromData=false means the widget says the value was submitted
  //   or is not distinguishable from submission, e.g. checkbox/multiple select.
  // Claim CI-SUBMITTED-EMPTY-ASSIGNS
  claim
    <k> decide(field(mode, true, false, true, true, false, true, false, true, false, empty))
        => assign(mode, empty) ... </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_code: default preservation is guarded by f.has_default().
  // Claim CI-NONDEFAULT-OMITTED-EMPTY-ASSIGNS
  claim
    <k> decide(field(mode, true, false, true, true, false, false, true, true, false, empty))
        => assign(mode, empty) ... </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_docstring/code: construct_instance only applies cleaned_data to editable,
  //   non-AutoField fields included by fields/exclude and present in cleaned_data.
  // Claim CI-INELIGIBLE-NOT-EDITABLE-SKIPS
  claim
    <k> decide(field(mode, false, false, true, true, false, true, true, false, false, nonEmpty))
        => skip ... </k>
    [all-path]

  // Claim CI-INELIGIBLE-AUTO-SKIPS
  claim
    <k> decide(field(mode, true, true, true, true, false, true, true, false, false, nonEmpty))
        => skip ... </k>
    [all-path]

  // Claim CI-INELIGIBLE-NOT-IN-CLEANED-SKIPS
  claim
    <k> decide(field(mode, true, false, false, true, false, true, true, false, false, nonEmpty))
        => skip ... </k>
    [all-path]

  // Claim CI-INELIGIBLE-NOT-IN-FIELDS-SKIPS
  claim
    <k> decide(field(mode, true, false, true, false, false, true, true, false, false, nonEmpty))
        => skip ... </k>
    [all-path]

  // Claim CI-INELIGIBLE-EXCLUDED-SKIPS
  claim
    <k> decide(field(mode, true, false, true, true, true, true, true, false, false, nonEmpty))
        => skip ... </k>
    [all-path]
endmodule

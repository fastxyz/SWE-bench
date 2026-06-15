requires "mini-django-fileinput.k"

module FILEINPUT-REQUIRED-SPEC
  imports MINI-DJANGO-FILEINPUT

  // SPEC-PROVENANCE:
  // - E1/E4/E5: FileInput with initial data must not render required.
  claim <k> buildRequiredAttr(FileInput, initial, true, true) => false </k> [all-path]

  // SPEC-PROVENANCE:
  // - E3: FileInput without initial data on a required field must render required.
  claim <k> buildRequiredAttr(FileInput, noInitial, true, true) => true </k> [all-path]

  // SPEC-PROVENANCE:
  // - E7: field.required remains a separate gate.
  claim <k> buildRequiredAttr(FileInput, initial, false, true) => false </k> [all-path]

  // SPEC-PROVENANCE:
  // - E7: Form.use_required_attribute remains a separate gate.
  claim <k> buildRequiredAttr(FileInput, initial, true, false) => false </k> [all-path]

  // SPEC-PROVENANCE:
  // - E6: ClearableFileInput keeps no-required behavior with initial data.
  claim <k> buildRequiredAttr(ClearableFileInput, initial, true, true) => false </k> [all-path]

  // SPEC-PROVENANCE:
  // - E6: ClearableFileInput keeps required behavior with no initial data.
  claim <k> buildRequiredAttr(ClearableFileInput, noInitial, true, true) => true </k> [all-path]

  // SPEC-PROVENANCE:
  // - PUBLIC_COMPATIBILITY_AUDIT: AdminFileWidget inherits through ClearableFileInput.
  claim <k> buildRequiredAttr(AdminFileWidget, initial, true, true) => false </k> [all-path]

  // SPEC-PROVENANCE:
  // - E9: generic visible non-file widgets keep the base Widget behavior.
  claim <k> buildRequiredAttr(GenericVisibleWidget, initial, true, true) => true </k> [all-path]

  // SPEC-PROVENANCE:
  // - E9: hidden widgets still suppress required through the base Widget behavior.
  claim <k> buildRequiredAttr(GenericHiddenWidget, noInitial, true, true) => false </k> [all-path]
endmodule

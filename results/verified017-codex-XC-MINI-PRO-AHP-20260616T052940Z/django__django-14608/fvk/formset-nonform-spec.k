// Constructed, not machine-checked.
requires "mini-django-errorlist.k"

module FORMSET-NONFORM-SPEC
  imports MINI-DJANGO-ERRORLIST

  // SPEC-PROVENANCE:
  // - E1/E2/E3: issue requires formset non-form errors to use nonform,
  //   mirroring Form.non_field_errors(error_class='nonfield').
  // - from_code: BaseFormSet.non_form_errors() calls full_clean() if needed
  //   and returns _non_form_errors.
  claim
    <k> nonFormErrors(unbound) => errorList(noErrors, nonform) ... </k>
    <nonFormErrors> _ => errorList(noErrors, nonform) </nonFormErrors>
    [all-path]

  // SPEC-PROVENANCE:
  // - E1/E2/E3: empty clean formset-level lists still carry the constructor
  //   signal for custom ErrorList implementations.
  claim
    <k> nonFormErrors(clean) => errorList(noErrors, nonform) ... </k>
    <nonFormErrors> _ => errorList(noErrors, nonform) </nonFormErrors>
    [all-path]

  // SPEC-PROVENANCE:
  // - E1/E2/E3: management-form errors are returned through
  //   formset.non_form_errors() and must render with nonform.
  claim
    <k> nonFormErrors(management) => errorList(managementErrors, nonform) ... </k>
    <nonFormErrors> _ => errorList(managementErrors, nonform) </nonFormErrors>
    [all-path]

  // SPEC-PROVENANCE:
  // - E1/E2/E3: max/min/custom clean ValidationError lists are the primary
  //   formset non-form errors and must render with nonform.
  claim
    <k> nonFormErrors(validation) => errorList(validationErrors, nonform) ... </k>
    <nonFormErrors> _ => errorList(validationErrors, nonform) </nonFormErrors>
    [all-path]

  // SPEC-PROVENANCE:
  // - E6: old public rendering expectation with no extra class is suspect
  //   legacy evidence, and this discriminator shows the model can see the bug.
  claim
    <k> classOf(errorList(validationErrors, noExtra)) => errorlist ... </k>
    [all-path]

  claim
    <k> classOf(errorList(validationErrors, nonform)) => errorlistNonform ... </k>
    [all-path]
endmodule

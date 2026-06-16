requires "mini-django-forms.k"

module READONLY-PASSWORD-HASH-FIELD-SPEC
  imports MINI-DJANGO-FORMS

  // SPEC-PROVENANCE:
  // - prompt: "Set disabled prop on ReadOnlyPasswordHashField"
  // - prompt: "this property could be set to True be default"
  // - code: repo/django/contrib/auth/forms.py sets kwargs.setdefault("disabled", True)
  claim
    <k> disabledOf(defaultRPHF(none)) => true </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - prompt: "Even if a user tampers with the field's value submitted to the
  //   server, it will be ignored in favor of the value from the form's initial data."
  // - prompt: "using the ReadOnlyPasswordHashField without implementing clean_password"
  // - code: BaseForm._clean_fields() uses get_initial_for_field() when field.disabled
  claim
    <k> cleanPassword(defaultRPHF(none), SUB:Val, INIT:Val) => INIT </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - prompt: "by default" supports a default, not a forced value.
  // - compatibility: callers may still explicitly pass disabled=False.
  // - code: kwargs.setdefault() preserves explicit kwargs.
  claim
    <k> disabledOf(defaultRPHF(some(false))) => false </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - compatibility frame for explicit disabled=False opt-out.
  // - code: BaseForm._clean_fields() reads submitted data when field.disabled is false.
  claim
    <k> cleanPassword(defaultRPHF(some(false)), SUB:Val, INIT:Val) => SUB </k>
    [all-path]
endmodule

requires "mini-django-form.k"

module AUTHENTICATION-FORM-SPEC
  imports MINI-DJANGO-FORM
  imports MAP-SYMBOLIC
  imports K-EQUAL

  // SPEC-PROVENANCE:
  // - from_prompt: "AuthenticationForm's username field doesn't render with maxlength HTML attribute anymore."
  //   => a non-hidden UsernameField rendered by AuthenticationForm must expose maxlength.
  // - from_public_tests: AuthenticationForm max_length matches a custom user model's username max_length.
  //   => positive user-model max_length ML is the effective limit.
  // - from_forms_contract: CharField.widget_attrs() returns maxlength when max_length is set and widget is not hidden.
  claim
    <k> initAuth(someLength(ML), usernameField(), false, LABEL, VNAME) => .K </k>
    <maxLength> _ => ML </maxLength>
    <attrs> A => mergeAttrs(A, widgetAttrs(usernameField(), false, ML)) </attrs>
    <label> LABEL => resolvedLabel(LABEL, VNAME) </label>
    requires ML >Int 0
    [all-path]

  // SPEC-PROVENANCE:
  // - from_public_tests: AuthenticationForm falls back to max_length 254 when the user model field has no max_length.
  // - from_prompt/forms_contract: that effective field max_length must be visible as maxlength on non-hidden UsernameField widgets.
  claim
    <k> initAuth(noLength(), usernameField(), false, LABEL, VNAME) => .K </k>
    <maxLength> _ => 254 </maxLength>
    <attrs> A => mergeAttrs(A, widgetAttrs(usernameField(), false, 254)) </attrs>
    <label> LABEL => resolvedLabel(LABEL, VNAME) </label>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_public_tests: AuthenticationForm supports subclasses replacing username with IntegerField.
  // - from_forms_contract: non-CharField widget_attrs decide their own attrs; the auth fix must not manually force maxlength.
  claim
    <k> initAuth(UML, otherField(), HIDDEN, LABEL, VNAME) => .K </k>
    <maxLength> _ => effectiveLength(UML) </maxLength>
    <attrs> A => A </attrs>
    <label> LABEL => resolvedLabel(LABEL, VNAME) </label>
    [all-path]
endmodule

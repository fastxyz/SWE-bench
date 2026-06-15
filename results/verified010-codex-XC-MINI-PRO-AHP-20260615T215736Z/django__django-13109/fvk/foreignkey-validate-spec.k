requires "mini-django-validation.k"

module FOREIGNKEY-VALIDATE-SPEC
  imports MINI-DJANGO-VALIDATION

  // SPEC-PROVENANCE:
  // - E1: "ForeignKey.validate() should validate using the base manager instead of the default manager."
  // - E2: form queryset uses Article._base_manager.all() to allow archived articles.
  // - E3: default-manager filtering incorrectly raised "does not exist".
  // - E4: validation checks DB existence, not archived business policy.
  claim
    <k> ValidateFK(BaseManager, VALUE:Int, true, DEFAULT_EXISTS:Bool, true) => Valid ... </k>
    [label(FK_BASE_MANAGER_ACCEPTS), all-path]

  // SPEC-PROVENANCE:
  // - E4: ORM validation still rejects values with no database row.
  claim
    <k> ValidateFK(BaseManager, VALUE:Int, false, DEFAULT_EXISTS:Bool, LIMIT_OK:Bool) => Invalid ... </k>
    [label(FK_BASE_MANAGER_REJECTS_MISSING), all-path]

  // SPEC-PROVENANCE:
  // - E6: existing code applies get_limit_choices_to() through complex_filter().
  // - The issue changes manager selection only.
  claim
    <k> ValidateFK(BaseManager, VALUE:Int, true, DEFAULT_EXISTS:Bool, false) => Invalid ... </k>
    [label(FK_LIMIT_CHOICES_STILL_APPLIES), all-path]

  // SPEC-PROVENANCE:
  // - E3: this is the legacy symptom model, not the intended postcondition.
  claim
    <k> ValidateFK(DefaultManager, VALUE:Int, true, false, true) => Invalid ... </k>
    [label(FK_LEGACY_DEFAULT_MANAGER_FAILS_ARCHIVED), all-path]
endmodule

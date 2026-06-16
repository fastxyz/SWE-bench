requires "mini-django-forms.k"

module DJANGO-FORMS-SPEC
  imports MINI-DJANGO-FORMS
  imports K-EQUAL

  // SPEC-PROVENANCE:
  // - I1/I3: BaseForm._clean_fields() must get disabled values through
  //   BoundField.initial rather than an independent callable initial path.
  // - I2/I4: BaseForm.changed_data must aggregate per-field decisions from
  //   BoundField._has_changed().
  // - S5: field-specific clean(), has_changed(), hook, and error behavior are
  //   frame conditions outside this abstract observable.
  claim
    <k> auditForm(FORM) => audited(CLEANED, CHANGED) ... </k>
    <fields> NAMES </fields>
    <boundFields> BFMAP </boundFields>
    requires BFMAP ==K boundFieldsFor(FORM, NAMES)
    ensures CLEANED ==K cleanViaBoundFields(FORM, NAMES, BFMAP)
     andBool CHANGED ==K changedViaBoundFields(FORM, NAMES, BFMAP)
    [all-path]
endmodule

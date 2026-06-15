requires "mini-django-formfield.k"

module FOREIGNKEY-FORMFIELD-SPEC
  imports MINI-DJANGO-FORMFIELD

  // SPEC-PROVENANCE:
  // - from_prompt: "RadioSelect widget for foreign keys should not present a
  //   blank option if blank=False" => non-blank explicit radio widget removes
  //   the generated empty label.
  // - from_code: fields_for_model() passes Meta.widgets through kwargs['widget'].
  claim
    <k> decideEmptyLabel(false, widget(radio), select, noExplicitEmptyLabel)
        => emptyNone
        ... </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: same radio-widget obligation.
  // - from_code: Field.__init__() uses form_class.widget when no widget kwarg
  //   is supplied, so a radio default widget is still the effective widget.
  claim
    <k> decideEmptyLabel(false, noWidget, radio, noExplicitEmptyLabel)
        => emptyNone
        ... </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: blank is invalid only when blank is not a valid selection.
  // - from_code: model fields with blank=True are not required form fields.
  claim
    <k> decideEmptyLabel(true, widget(radio), select, noExplicitEmptyLabel)
        => emptyDefault
        ... </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: select-widget blank option is idiomatic even for required
  //   fields, so non-radio select behavior is framed.
  claim
    <k> decideEmptyLabel(false, widget(select), select, noExplicitEmptyLabel)
        => emptyDefault
        ... </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_code: explicit formfield kwargs override generated defaults.
  // - from_compatibility: admin radio fields pass empty_label explicitly.
  claim
    <k> decideEmptyLabel(false, widget(radio), select, explicitEmptyLabel)
        => emptyExplicit
        ... </k>
    [all-path]
endmodule

requires "mini-admin-widget.k"

module MINI-ADMIN-WIDGET-SPEC
  imports MINI-ADMIN-WIDGET

  // SPEC-PROVENANCE:
  // - from_prompt: "Allow overridding widget in formfield_for_manytomany()."
  //   => explicit widget kwargs must win over admin's automatic many-to-many widgets.
  // - from_prompt: "This is different from the formfield_for_foreignkey() function."
  //   => mirror formfield_for_foreignkey's "if 'widget' not in kwargs" precedence.
  // - from_docs: ModelAdmin.formfield_for_manytomany can be overridden and forwards **kwargs.
  //   => keep **kwargs as the customization channel.
  claim
    <k> m2mFormfield(true, someWidget(W:Widget), A:AdminOption, Q:QuerysetState)
     => formField(W, QS:QuerysetState) ... </k>
    ensures QS ==K explicitQueryset orBool QS ==K inferredQueryset
    [all-path]

  // SPEC-PROVENANCE:
  // - from_code_frame: without an explicit widget, existing autocomplete/raw-id/filter/default
  //   behavior is preserved.
  claim <k> m2mFormfield(true, noWidget, autocompleteOption, Q:QuerysetState)
        => formField(autocompleteWidget, QS:QuerysetState) ... </k>
    ensures QS ==K explicitQueryset orBool QS ==K inferredQueryset
    [all-path]

  claim <k> m2mFormfield(true, noWidget, rawIdOption, Q:QuerysetState)
        => formField(rawIdWidget, QS:QuerysetState) ... </k>
    ensures QS ==K explicitQueryset orBool QS ==K inferredQueryset
    [all-path]

  claim <k> m2mFormfield(true, noWidget, filteredOption, Q:QuerysetState)
        => formField(filteredWidget, QS:QuerysetState) ... </k>
    ensures QS ==K explicitQueryset orBool QS ==K inferredQueryset
    [all-path]

  claim <k> m2mFormfield(true, noWidget, noAdminWidget, Q:QuerysetState)
        => formField(defaultWidget, QS:QuerysetState) ... </k>
    ensures QS ==K explicitQueryset orBool QS ==K inferredQueryset
    [all-path]

  // SPEC-PROVENANCE:
  // - from_code_frame: many-to-many fields with non-auto-created intermediary models are
  //   intentionally not shown in admin and return None/no formfield.
  claim
    <k> m2mFormfield(false, W:MaybeWidget, A:AdminOption, Q:QuerysetState)
     => noFormField ... </k>
    [all-path]
endmodule

requires "mini-admin-empty-label.k"

module ADMIN-RADIO-EMPTY-LABEL-SPEC
  imports MINI-ADMIN-EMPTY-LABEL

  // SPEC-PROVENANCE:
  // - from_prompt: "empty_label from kwargs should take precedence over _('None')" =>
  //   for blank radio ForeignKey fields, an explicit kwarg value is preserved.
  // - from_docs: ModelChoiceField empty_label can be a custom label or None =>
  //   key presence, not truthiness, is the intended precedence discriminator.
  claim <k> resolveRadioEmptyLabel(true, present(L:Label)) => L ... </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: existing default is acceptable only when no custom value is
  //   supplied; the issue objects to dropping the supplied value.
  claim <k> resolveRadioEmptyLabel(true, absent) => defaultNoneText ... </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_code/docs: nonblank RadioSelect ModelChoiceField suppresses an empty
  //   choice; preserving this behavior is outside the reported regression.
  claim <k> resolveRadioEmptyLabel(false, M:MaybeLabel) => noEmptyChoice ... </k>
    [all-path]
endmodule

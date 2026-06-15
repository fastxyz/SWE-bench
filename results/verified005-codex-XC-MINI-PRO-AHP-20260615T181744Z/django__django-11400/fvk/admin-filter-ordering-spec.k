requires "mini-admin-ordering.k"

module ADMIN-FILTER-ORDERING-SPEC
  imports MINI-ADMIN-ORDERING

  // SPEC-PROVENANCE:
  // - from_prompt: "RelatedFieldListFilter doesn't fall back to the ordering defined in Model._meta.ordering."
  //   => no related admin ordering must resolve to the related model's Meta.ordering.
  claim <k> relatedFieldChoices(unregistered, M:Ordering)
        => getChoices(related, noLimit, M) </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: "unless ordering is defined on the related model's ModelAdmin class it stays an empty tuple"
  //   => the empty tuple is the no-admin-ordering sentinel and must fall back to Meta.ordering.
  claim <k> relatedFieldChoices(registered(emptyTuple), M:Ordering)
        => getChoices(related, noLimit, M) </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_code: ModelAdmin.get_field_queryset() also treats None as no specified ordering.
  //   => a custom get_ordering() returning None falls back to Meta.ordering.
  claim <k> relatedFieldChoices(registered(none), M:Ordering)
        => getChoices(related, noLimit, M) </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: "unless ordering is defined on the related model's ModelAdmin class"
  //   => a specified related ModelAdmin ordering takes precedence over Meta.ordering.
  // - from_code: ModelAdmin.get_field_queryset() treats values other than None and () as specified.
  claim <k> relatedFieldChoices(registered(O:Ordering), M:Ordering)
        => getChoices(related, noLimit, O) </k>
    requires specifiedOrdering(O)
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: "RelatedOnlyFieldListFilter doesn't order the related model at all, even if ordering is defined"
  //   => related-only choices must pass specified related ModelAdmin ordering to get_choices().
  // - from_code: the existing related-only restriction is limit_choices_to={'pk__in': pk_qs}.
  claim <k> relatedOnlyFieldChoices(registered(O:Ordering), M:Ordering)
        => getChoices(relatedOnly, pkInLimit, O) </k>
    requires specifiedOrdering(O)
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: related-only choices are still related-field choices and inherit the same Meta.ordering fallback.
  // - from_code: RelatedOnlyFieldListFilter subclasses RelatedFieldListFilter and overrides only field_choices().
  claim <k> relatedOnlyFieldChoices(unregistered, M:Ordering)
        => getChoices(relatedOnly, pkInLimit, M) </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: empty-tuple ordering is the reported bug source, so related-only must not preserve it either.
  claim <k> relatedOnlyFieldChoices(registered(emptyTuple), M:Ordering)
        => getChoices(relatedOnly, pkInLimit, M) </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_code: None is not a valid order_by iterable, so it is not a specified ordering.
  claim <k> relatedOnlyFieldChoices(registered(none), M:Ordering)
        => getChoices(relatedOnly, pkInLimit, M) </k>
    [all-path]
endmodule

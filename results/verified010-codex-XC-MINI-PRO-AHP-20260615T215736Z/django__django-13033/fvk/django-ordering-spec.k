requires "mini-django-ordering.k"

module DJANGO-ORDERING-SPEC
  imports MINI-DJANGO-ORDERING

  // SPEC-PROVENANCE:
  // - from_prompt: "order_by('record__root_id') should result in ORDER BY root_id"
  //   => a multi-hop FK attname lookup is a direct FK-column ordering.
  // - from_docs: "explicitly order by the relation `_id` field"
  //   => `_id` is the documented escape hatch from related default ordering.
  claim classify(field(true, "root_id", true),
                 lookup("record__root_id", "root_id", false))
        => direct

  // SPEC-PROVENANCE:
  // - from_prompt: "order_by('record__root') should use OneModel.Meta.ordering"
  // - from_docs: "If you try to order by a field that is a relation to another
  //   model, Django will use the default ordering on the related model"
  //   => relation-name lookup expands related model default ordering.
  claim classify(field(true, "root_id", true),
                 lookup("record__root", "root", false))
        => expand

  // SPEC-PROVENANCE:
  // - from_public_test: "ordering by a foreign key by its attribute name
  //   prevents the query from inheriting its related model ordering option"
  //   => existing one-hop FK attname behavior is preserved.
  claim classify(field(true, "author_id", true),
                 lookup("author_id", "author_id", false))
        => direct

  // SPEC-PROVENANCE:
  // - from_code_comment: related ordering expansion is skipped for "the pk
  //   shortcut" => pk shortcut remains direct/non-expanded.
  claim classify(field(true, "id", true),
                 lookup("pk", "pk", true))
        => direct
endmodule

// Constructed, not machine-checked.
// Formal claims for django__django-16938 against mini-serializer-queryset.k.

requires "mini-serializer-queryset.k"

module SERIALIZER-M2M-SPEC
  imports MINI-SERIALIZER-QUERYSET
  imports INT
  imports LIST

  // SPEC-PROVENANCE:
  // - from_prompt: "Serialization of many to many relation with custom manager
  //   using select_related cause FieldError" => serialization must not fail
  //   merely because the related model default manager used select_related.
  // - from_prompt: "Serialize raise exception because is not possible to
  //   combine select_related and only" => clear inherited select_related before
  //   the primary-key-only optimization.
  // - from_code: python.py and xml_serializer.py serialize non-natural m2m
  //   relations as related primary keys and use only("pk") for that path.
  claim <k> serializeM2MNonNatural(
              uncached(qs(SEL, LOAD, ROWS))
            )
         => ok(projectPks(ROWS)) </k>

  // SPEC-PROVENANCE:
  // - from_code: the serializer prefers _prefetched_objects_cache when it has
  //   the field name, so cached related objects are serialized directly.
  claim <k> serializeM2MNonNatural(cached(ROWS))
         => ok(projectPks(ROWS)) </k>

  // SPEC-PROVENANCE:
  // - from_prompt traceback: the pre-fix code reaches FieldError for
  //   select_related("master") combined with only("pk").
  // - from_code: select_related_descend() raises when a requested relation is
  //   absent from the select mask.
  claim <k> serializeM2MNonNaturalOld(
              qs(someSelectRelated(), LOAD, ROWS)
            )
         => fieldError() </k>
endmodule

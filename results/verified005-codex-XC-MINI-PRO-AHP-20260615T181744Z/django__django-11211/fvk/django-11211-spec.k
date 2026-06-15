requires "mini-django-prefetch.k"

module DJANGO-11211-SPEC
  imports MINI-DJANGO-PREFETCH
  imports K-EQUAL

  // SPEC-PROVENANCE:
  // - from_prompt: "UUIDField(primary_key=True)" and object id "CharField" with
  //   "prefetch_related('foo')" returning None => valid textual UUID object ids
  //   must match loaded UUID primary keys during GFK prefetch.
  // - from_docs: repo/docs/ref/models/querysets.txt says prefetch_related()
  //   supports GenericForeignKey and does the joining in Python.
  // - from_code: GenericForeignKey.gfk_key delegates source-side normalization
  //   to model._meta.pk.get_prep_value().
  claim
    <k> uuidPrep(Str(S:String)) => UUID(canonUuid(S)) ... </k>
    requires validUuid(S)
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: the same Bar.foo_object_id value should recover Foo.id
  //   through Bar.objects.all().prefetch_related('foo').
  // - from_code: prefetch_one_level() uses equality of rel_obj_attr() and
  //   instance_attr() values as dictionary keys.
  claim
    <k> keysMatch(Str(S:String), UUID(canonUuid(S)), Foo) => true ... </k>
    requires validUuid(S)
    [all-path]

  // SPEC-PROVENANCE:
  // - from_field_contract: None remains None under Field preparation.
  // - from_code: GenericForeignKey.get_prefetch_queryset() skips None object ids.
  claim
    <k> uuidPrep(None) => None ... </k>
    [all-path]
endmodule

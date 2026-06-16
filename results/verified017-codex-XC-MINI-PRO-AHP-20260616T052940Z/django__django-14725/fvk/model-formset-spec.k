requires "mini-model-formset.k"

module MINI-MODEL-FORMSET-SPEC
  imports MINI-MODEL-FORMSET

  // SPEC-PROVENANCE:
  // - from_prompt: "Provide a way for model formsets to disallow new object creation"
  //   => with edit_only enabled, save() must not create any new objects.
  // - from_prompt: "extra=0 ... isn't reliable ... send additional post data"
  //   => the claim quantifies over every eligibleNew count N, including
  //      tampered-management-form extra submissions.
  // - from_code: V2 checks self.edit_only inside BaseModelFormSet.save() before
  //   virtual dispatch to save_new_objects().
  claim
    <k> save(true, E:Int, N:Int) => .K </k>
    <created> _ => 0 </created>
    <newObjects> _ => 0 </newObjects>
    <result> _ => E </result>
    <editOnly> _ => true </editOnly>
    requires E >=Int 0 andBool N >=Int 0
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: the new mode is opt-in; existing model formset creation
  //   behavior remains available when edit_only is false.
  // - from_code: normal save() still concatenates save_existing_objects() and
  //   save_new_objects().
  claim
    <k> save(false, E:Int, N:Int) => .K </k>
    <created> _ => N </created>
    <newObjects> _ => N </newObjects>
    <result> _ => E +Int N </result>
    <editOnly> _ => false </editOnly>
    requires E >=Int 0 andBool N >=Int 0
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: "disallow new object creation" applies to the base
  //   save_new_objects() creation path as well as save().
  // - from_code: BaseModelFormSet.save_new_objects() initializes new_objects
  //   and returns before iterating extra_forms when edit_only is true.
  claim
    <k> saveNewObjects(true, N:Int) => .K </k>
    <created> _ => 0 </created>
    <newObjects> _ => 0 </newObjects>
    <result> _ => 0 </result>
    <editOnly> _ => true </editOnly>
    requires N >=Int 0
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: model formsets normally support adding objects unless the
  //   caller opts into edit-only behavior.
  // - from_code: BaseModelFormSet.save_new_objects() keeps the existing loop
  //   for changed, non-deleted extra forms when edit_only is false.
  claim
    <k> saveNewObjects(false, N:Int) => .K </k>
    <created> _ => N </created>
    <newObjects> _ => N </newObjects>
    <result> _ => N </result>
    <editOnly> _ => false </editOnly>
    requires N >=Int 0
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: "way for model formsets" requires a public constructor path.
  // - from_code: modelformset_factory(), inlineformset_factory(), and
  //   generic_inlineformset_factory() expose or propagate edit_only.
  claim
    <k> factory(B:Bool) => .K </k>
    <editOnly> _ => B </editOnly>
    [all-path]
endmodule

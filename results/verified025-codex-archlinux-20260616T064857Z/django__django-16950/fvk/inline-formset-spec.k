requires "mini-inline-formset.k"

module MINI-INLINE-FORMSET-SPEC
  imports MINI-INLINE-FORMSET

  // SPEC-PROVENANCE:
  // - from_prompt: "Django Admin with Inlines not using UUIDField default value"
  //   and "new_object.id ... all_valid(formsets) ... new_object.id None"
  //   => constructing/validating inline forms must not clear a non-primary
  //   UUID to_field value on the unsaved parent object.
  // - from_public_test: test_inlineformset_factory_nulls_default_pks_alternate_key_relation
  //   => the inline hidden field's initial value remains empty for a defaulted
  //   alternate-key relation.
  claim
    <k> addFields(true, altField, true, someValue) => .K </k>
    <parentTarget> noneValue => someValue </parentTarget>
    <fieldInitial> noneValue => noneValue </fieldInitial>
    <parentMutated> false => false </parentMutated>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_public_test: tests for #24377/#24958 defaulted UUID primary keys
  //   => defaulted primary keys are still hidden as empty initial values.
  // - from_code_comment: "The pk will be regenerated on the save request"
  //   => the parent pk clearing behavior is intentionally preserved.
  claim
    <k> addFields(true, pkField, true, someValue) => .K </k>
    <parentTarget> someValue => noneValue </parentTarget>
    <fieldInitial> someValue => noneValue </fieldInitial>
    <parentMutated> false => true </parentMutated>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_code: InlineForeignKeyField historically derived initial from the
  //   parent instance when no override was supplied.
  // - from_fix: BaseInlineFormSet supplies initial=None only for the defaulted
  //   non-PK to_field case.
  claim
    <k> initInlineField(true, someValue, noneValue) => .K </k>
    <fieldInitial> someValue => noneValue </fieldInitial>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_code: existing callers without explicit initial must keep deriving
  //   initial from the parent instance.
  claim
    <k> initInlineField(false, someValue, noneValue) => .K </k>
    <fieldInitial> noneValue => someValue </fieldInitial>
    [all-path]
endmodule

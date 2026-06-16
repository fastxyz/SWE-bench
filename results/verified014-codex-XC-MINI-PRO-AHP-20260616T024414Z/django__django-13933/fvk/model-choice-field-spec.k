requires "mini-django-forms.k"

module MODEL-CHOICE-FIELD-SPEC
  imports MINI-DJANGO-FORMS
  imports MAP

  // SPEC-PROVENANCE:
  // - from_prompt: "ModelChoiceField does not provide value of invalid choice"
  //   => invalid_choice errors must include params['value'].
  // - from_prompt: "modifying the default error message"
  //   => the default invalid_choice message includes the submitted value.
  // - from_code: empty values return None before lookup.
  claim <k> modelChoiceToPython(emptyValue()) => ok(emptyValue()) ... </k>
        <queryset> QS:Map </queryset>
        <errorMessage> modelChoiceInvalid() </errorMessage>
        [all-path]

  // SPEC-PROVENANCE:
  // - from_code: valid queryset lookups return the matched model instance.
  // - from_prompt: the change is limited to invalid-choice error behavior.
  claim <k> modelChoiceToPython(submitted(K:String)) => ok(OBJ) ... </k>
        <queryset> K |-> OBJ:Value QS:Map </queryset>
        <errorMessage> modelChoiceInvalid() </errorMessage>
        [all-path]

  // SPEC-PROVENANCE:
  // - from_code: model instances of the queryset model are converted to the
  //   lookup key before queryset.get().
  // - from_prompt: the fix should not change valid model-instance behavior.
  claim <k> modelChoiceToPython(modelInstance(K:String)) => ok(OBJ) ... </k>
        <queryset> K |-> OBJ:Value QS:Map </queryset>
        <errorMessage> modelChoiceInvalid() </errorMessage>
        [all-path]

  // SPEC-PROVENANCE:
  // - from_code: model instances of the queryset model are converted to the
  //   lookup key before queryset.get().
  // - from_prompt: invalid-choice params expose the value used for validation.
  claim <k> modelChoiceToPython(modelInstance(K:String))
            => validationError(
                 "invalid_choice",
                 "Select a valid choice. " +String K +String " is not one of the available choices.",
                 "value" |-> submitted(K)
               )
            ... </k>
        <queryset> QS:Map </queryset>
        <errorMessage> modelChoiceInvalid() </errorMessage>
    requires notBool(K in_keys(QS))
        [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: invalid submitted choices must expose the invalid value.
  // - from_choicefield: ChoiceField passes params {'value': value}.
  claim <k> modelChoiceToPython(submitted(K:String))
            => validationError(
                 "invalid_choice",
                 "Select a valid choice. " +String K +String " is not one of the available choices.",
                 "value" |-> submitted(K)
               )
            ... </k>
        <queryset> QS:Map </queryset>
        <errorMessage> modelChoiceInvalid() </errorMessage>
    requires notBool(K in_keys(QS))
        [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: even conversion/type failures should be invalid_choice
  //   errors that can interpolate the offending value.
  // - from_code: ValueError and TypeError are caught by the same except block.
  claim <k> modelChoiceToPython(badType(K:String))
            => validationError(
                 "invalid_choice",
                 "Select a valid choice. " +String K +String " is not one of the available choices.",
                 "value" |-> badType(K)
               )
            ... </k>
        <queryset> QS:Map </queryset>
        <errorMessage> modelChoiceInvalid() </errorMessage>
        [all-path]
endmodule

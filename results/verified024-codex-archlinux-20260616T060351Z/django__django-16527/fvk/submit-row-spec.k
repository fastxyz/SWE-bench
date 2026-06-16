requires "mini-submit-row.k"

module SUBMIT-ROW-SPEC
  imports MINI-SUBMIT-ROW

  // SPEC-PROVENANCE:
  // - from_prompt: "`show_save_as_new` in admin can add without this permission"
  //   => users without add permission must not see the Save as new control.
  // - from_prompt: "`save_as_new` is a add modification"
  //   => Save as new requires add permission.
  claim <k> showSaveAsNew(IS_POPUP, false, HAS_CHANGE_PERMISSION, CHANGE, SAVE_AS)
        => false
      </k>
    [label(NO_ADD)]

  // SPEC-PROVENANCE:
  // - from_prompt_hint: "Save as New is a save too (current object)"
  //   => the control still requires change permission.
  claim <k> showSaveAsNew(IS_POPUP, HAS_ADD_PERMISSION, false, CHANGE, SAVE_AS)
        => false
      </k>
    [label(NO_CHANGE)]

  // SPEC-PROVENANCE:
  // - from_prompt_hint: "current object"
  //   => the control appears only on an existing-object change form.
  claim <k> showSaveAsNew(IS_POPUP, HAS_ADD_PERMISSION, HAS_CHANGE_PERMISSION, false, SAVE_AS)
        => false
      </k>
    [label(NO_CHANGE_FORM)]

  // SPEC-PROVENANCE:
  // - from_code_frame: pre-existing popup exclusion retained.
  claim <k> showSaveAsNew(true, HAS_ADD_PERMISSION, HAS_CHANGE_PERMISSION, CHANGE, SAVE_AS)
        => false
      </k>
    [label(POPUP)]

  // SPEC-PROVENANCE:
  // - from_code_frame: pre-existing `save_as` feature flag retained.
  claim <k> showSaveAsNew(IS_POPUP, HAS_ADD_PERMISSION, HAS_CHANGE_PERMISSION, CHANGE, false)
        => false
      </k>
    [label(SAVE_AS_DISABLED)]

  // SPEC-PROVENANCE:
  // - from_prompt: Save as new is permitted when the add operation is allowed.
  // - from_prompt_hint: the action also saves the current object, so change
  //   permission and a change form are required.
  claim <k> showSaveAsNew(false, true, true, true, true)
        => true
      </k>
    [label(POSITIVE)]
endmodule

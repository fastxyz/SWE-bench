requires "mini-field-copy.k"

module FIELD-DEEPCOPY-SPEC
  imports MINI-FIELD-COPY
  imports MAP-SYMBOLIC
  imports K-EQUAL

  // SPEC-PROVENANCE:
  // - from_prompt: "Form Field's __deepcopy__ does not (deep)copy the error messages"
  //   => the copied field must not share the original error_messages object.
  // - from_prompt: "all copies of the same field share the same dictionary"
  //   => the failing observable is object aliasing, modeled by object ids in <heap>.
  // - from_prompt: "any modification of either the dictionary or the error message itself"
  //   => the copied error_messages object preserves payload but has fresh identity.
  // - from_code: Field.__deepcopy__ copies widget, error_messages, and validators;
  //   validators are a shallow list copy, matching the existing public behavior.
  claim [FIELD-DEEPCOPY-COPY-ERRORS]:
    <k> deepcopyField(F:Int) => N ... </k>
    <heap>
      F  |-> FieldObj(WO, EO, VO)
      WO |-> WidgetObj(WP)
      EO |-> ErrorMessagesObj(EP)
      VO |-> ValidatorsObj(VP)
      =>
      F  |-> FieldObj(WO, EO, VO)
      WO |-> WidgetObj(WP)
      EO |-> ErrorMessagesObj(EP)
      VO |-> ValidatorsObj(VP)
      N  |-> FieldObj(N +Int 1, N +Int 2, N +Int 3)
      (N +Int 1) |-> WidgetObj(WP)
      (N +Int 2) |-> ErrorMessagesObj(EP)
      (N +Int 3) |-> ValidatorsObj(VP)
    </heap>
    <next> N => N +Int 4 </next>
    requires F  <Int N
     andBool WO <Int N
     andBool EO <Int N
     andBool VO <Int N
     andBool F  =/=Int WO
     andBool F  =/=Int EO
     andBool F  =/=Int VO
     andBool WO =/=Int EO
     andBool WO =/=Int VO
     andBool EO =/=Int VO
    ensures (N +Int 2) =/=Int EO
    [all-path]
endmodule

requires "mini-python-blueprint.k"

module BLUEPRINT-NAME-SPEC
  imports MINI-PYTHON-BLUEPRINT

  // SPEC-PROVENANCE:
  // - E1: "Require a non-empty name for Blueprints" => empty constructor name is invalid.
  // Claim id: C-INIT-EMPTY.
  claim [cInitEmpty]:
    <k> initBlueprint("") => valueErrorRaised ... </k>
    <bpName> BP => BP </bpName>
    <appBlueprints> M => M </appBlueprints>
    <gotRegistered> R => R </gotRegistered>

  // SPEC-PROVENANCE:
  // - E3: dots separate nested blueprint names and endpoint names => existing dotted-name
  //   validation remains for non-empty constructor names.
  // Claim id: C-INIT-DOTTED.
  claim [cInitDotted]:
    <k> initBlueprint(NAME) => valueErrorRaised ... </k>
    <bpName> BP => BP </bpName>
    <appBlueprints> M => M </appBlueprints>
    <gotRegistered> R => R </gotRegistered>
    requires NAME =/=String "" andBool hasDot(NAME)

  // SPEC-PROVENANCE:
  // - E2: valid blueprint names prefix endpoints => non-empty, non-dotted names still initialize.
  // Claim id: C-INIT-NONEMPTY.
  claim [cInitNonempty]:
    <k> initBlueprint(NAME) => okInit(NAME) ... </k>
    <bpName> _ => NAME </bpName>
    requires NAME =/=String "" andBool notBool hasDot(NAME)

  // SPEC-PROVENANCE:
  // - E1: empty names are invalid.
  // - E5: register_blueprint name= changes the pre-dotted effective name.
  // Claim id: C-REGISTER-EMPTY-OVERRIDE.
  claim [cRegisterEmptyOverride]:
    <k> registerBlueprint(SELF, withName(""), PREFIX, CONFLICT) => valueErrorRaised ... </k>
    <appBlueprints> M => M </appBlueprints>
    <gotRegistered> R => R </gotRegistered>

  // SPEC-PROVENANCE:
  // - E1: empty names are invalid; covers mutated/subclassed objects whose stored name is empty.
  // Claim id: C-REGISTER-EMPTY-DEFAULT.
  claim [cRegisterEmptyDefault]:
    <k> registerBlueprint("", noName, PREFIX, CONFLICT) => valueErrorRaised ... </k>
    <appBlueprints> M => M </appBlueprints>
    <gotRegistered> R => R </gotRegistered>

  // SPEC-PROVENANCE:
  // - E2/E5: non-empty effective names remain valid and keep existing registration behavior.
  // Claim id: C-REGISTER-NONEMPTY-NOCONFLICT.
  claim [cRegisterNonemptyNoConflict]:
    <k> registerBlueprint(SELF, OPT, PREFIX, false)
      => okRegister(effectiveBlueprintName(PREFIX, resolvedName(OPT, SELF))) ... </k>
    <appBlueprints> M
      => M [ effectiveBlueprintName(PREFIX, resolvedName(OPT, SELF)) <- SELF ]
    </appBlueprints>
    <gotRegistered> false => true </gotRegistered>
    requires resolvedName(OPT, SELF) =/=String ""
endmodule

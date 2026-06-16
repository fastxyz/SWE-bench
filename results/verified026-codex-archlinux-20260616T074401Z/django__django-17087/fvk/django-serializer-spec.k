requires "mini-python-serializer.k"

module DJANGO-SERIALIZER-SPEC
  imports MINI-PYTHON-SERIALIZER

  // SPEC-PROVENANCE:
  // - from_prompt: "The right value should be
  //   appname.models.Profile.Capability.default" =>
  //   class-bound methods on importable nested classes include the class
  //   qualified name, not only the innermost class name.
  // - from_code: FunctionTypeSerializer serializes class-bound methods by
  //   returning a dotted path and an import for the defining module.
  claim
    <k> serialize(classMethod(MODULE:String, CLASSQUAL:String, NAME:String))
      => serialized(dottedClassMethod(MODULE, CLASSQUAL, NAME), importStmt(MODULE))
      ... </k>
    requires notBool hasLocalMarker(CLASSQUAL)
    [all-path]

  // SPEC-PROVENANCE:
  // - from_public_test/code: local function references are rejected when their
  //   qualified name contains local-scope markers.
  // - from_full_intent: migrations should not emit an unimportable dotted path.
  claim
    <k> serialize(classMethod(MODULE:String, CLASSQUAL:String, NAME:String))
      => valueError(couldNotFind(NAME, MODULE)) ... </k>
    requires hasLocalMarker(CLASSQUAL)
    [all-path]

  // SPEC-PROVENANCE:
  // - from_code: lambdas are explicitly unsupported serializer inputs.
  // - from_frame_condition: moving the lambda check before the class-bound branch
  //   makes the existing lambda rejection uniform.
  claim
    <k> serialize(lambdaFunction)
      => valueError("Cannot serialize function: lambda") ... </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_frame_condition: non-class-bound importable functions keep the
  //   existing module + function qualified-name serializer behavior.
  claim
    <k> serialize(functionValue(MODULE:String, QUAL:String, NAME:String))
      => serialized(dottedFunction(MODULE, QUAL), importStmt(MODULE)) ... </k>
    requires notBool hasLocalMarker(QUAL)
    [all-path]

  // SPEC-PROVENANCE:
  // - from_public_test/code: local non-class-bound functions are rejected.
  // - from_frame_condition: V2 preserves that existing branch.
  claim
    <k> serialize(functionValue(MODULE:String, QUAL:String, NAME:String))
      => valueError(couldNotFind(NAME, MODULE)) ... </k>
    requires hasLocalMarker(QUAL)
    [all-path]

  // SPEC-PROVENANCE:
  // - from_code: functions without a module are explicitly unsupported.
  // - from_frame_condition: V2 preserves that existing branch.
  claim
    <k> serialize(noModuleFunction(NAME:String))
      => valueError("Cannot serialize function: No module") ... </k>
    [all-path]
endmodule

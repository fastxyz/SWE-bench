requires "mini-pyreverse.k"

module PYREVERSE-TYPEHINTS-SPEC
  imports MINI-PYREVERSE

  // SPEC-PROVENANCE:
  // - E1/E2: "Use Python type hints" and the issue sample
  //   `def __init__(self, a: str = None): self.a = a`.
  // - from_code: V1 models `self.attr = attr` by adding the parameter
  //   annotation to the existing `AssignAttr.infer()` values.
  claim
    <k> collectAssignAttr => .K </k>
    <valueTypes> VS:Types </valueTypes>
    <annAssign> noAnn </annAssign>
    <paramAnn> ann(T:Type) </paramAnn>
    <collected> _ => merge(VS, types(T, .Types)) </collected>
    [all-path]

  // SPEC-PROVENANCE:
  // - E1: type annotations should feed UML generation.
  // - from_code: V1 adds `AnnAssign.annotation` inference to both assignment
  //   target paths.
  claim
    <k> collectAssignName => .K </k>
    <valueTypes> VS:Types </valueTypes>
    <annAssign> ann(T:Type) </annAssign>
    <collected> _ => merge(VS, types(T, .Types)) </collected>
    [all-path]

  claim
    <k> collectAssignAttr => .K </k>
    <valueTypes> VS:Types </valueTypes>
    <annAssign> ann(T:Type) </annAssign>
    <paramAnn> noAnn </paramAnn>
    <collected> _ => merge(VS, types(T, .Types)) </collected>
    [all-path]

  // SPEC-PROVENANCE:
  // - E5: preserve value inference when no annotation is present.
  claim
    <k> collectAssignAttr => .K </k>
    <valueTypes> VS:Types </valueTypes>
    <annAssign> noAnn </annAssign>
    <paramAnn> noAnn </paramAnn>
    <collected> _ => VS </collected>
    [all-path]

  // SPEC-PROVENANCE:
  // - E3: expected visible attribute type for the sample.
  // - from_code: `class_names` ignores non-class values such as None and
  //   displays class nodes that are not already in the diagram.
  claim
    <k> collectAssignAttr ~> render => .K </k>
    <valueTypes> types(NoneType, .Types) </valueTypes>
    <annAssign> noAnn </annAssign>
    <paramAnn> ann(builtin(str)) </paramAnn>
    <diagramTypes> .Types </diagramTypes>
    <displayed> _ => types(builtin(str), .Types) </displayed>
    [all-path]

  // SPEC-PROVENANCE:
  // - E6: preserve existing association-oriented behavior for user classes
  //   already present in the diagram.
  claim
    <k> render => .K </k>
    <collected> types(user(Thing), .Types) </collected>
    <diagramTypes> types(user(Thing), .Types) </diagramTypes>
    <displayed> _ => .Types </displayed>
    [all-path]
endmodule

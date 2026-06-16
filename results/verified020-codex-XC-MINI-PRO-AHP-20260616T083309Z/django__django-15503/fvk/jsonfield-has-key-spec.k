requires "mini-jsonpath.k"

module JSONFIELD-HAS-KEY-SPEC
  imports MINI-JSONPATH

  // SPEC-PROVENANCE:
  // - E-001/E-002/E-003/E-004: numeric-looking RHS lookup keys are object keys.
  claim hasKeyRhsPath(numeric(1111) .Keys, true)
    => member(intString(1111)) .Components

  // SPEC-PROVENANCE:
  // - E-005: numeric transform prefixes remain array indexes.
  claim hasKeyRhsPath(text("d") numeric(1) text("f") .Keys, true)
    => member("d") index(1) member("f") .Components

  // SPEC-PROVENANCE:
  // - E-001/E-003: has_keys and has_any_keys share per-key compilation.
  claim hasKeyRhsPath(numeric(7) .Keys, true)
    => member(intString(7)) .Components

  // SPEC-PROVENANCE:
  // - E-006: internal KeyTransform existence checks use transform semantics.
  claim hasKeyRhsPath(text("d") numeric(0) .Keys, false)
    => member("d") index(0) .Components
endmodule

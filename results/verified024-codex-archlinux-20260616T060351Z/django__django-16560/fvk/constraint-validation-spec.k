requires "mini-constraint-validation.k"

module CONSTRAINT-VALIDATION-SPEC
  imports MINI-CONSTRAINT-VALIDATION
  imports MAP
  imports STRING
  imports BOOL

  // SPEC-PROVENANCE:
  // - E-1/E-2/E-3: the public issue requires a violation_error_code API.
  claim <k> init(Code(S:String)) => .K </k>
        <code> NoCode => Code(S) </code>
        <kwargs> .Map </kwargs>
        <out> NoOutcome </out>
        [all-path]

  // SPEC-PROVENANCE:
  // - E-4/E-6: omitting a code preserves the prior default.
  claim <k> init(NoCode) => .K </k>
        <code> NoCode </code>
        <kwargs> .Map </kwargs>
        <out> NoOutcome </out>
        [all-path]

  // SPEC-PROVENANCE:
  // - I-3: deconstruction must preserve custom code for migrations/cloning.
  claim <k> deconstruct => .K </k>
        <code> Code(S:String) </code>
        <kwargs> .Map => .Map [ "violation_error_code" <- S ] </kwargs>
        <out> NoOutcome </out>
        [all-path]

  // SPEC-PROVENANCE:
  // - I-6: deconstruction without custom code remains unchanged.
  claim <k> deconstruct => .K </k>
        <code> NoCode </code>
        <kwargs> .Map </kwargs>
        <out> NoOutcome </out>
        [all-path]

  // SPEC-PROVENANCE:
  // - I-4/E-7: CheckConstraint uses the constraint violation message path.
  claim <k> validate(Check, true) => .K </k>
        <code> C:Code </code>
        <kwargs> .Map </kwargs>
        <out> NoOutcome => ValidationError(C) </out>
        [all-path]

  // SPEC-PROVENANCE:
  // - I-4/E-7: expression UniqueConstraint uses the constraint violation path.
  claim <k> validate(UniqueExpr, true) => .K </k>
        <code> C:Code </code>
        <kwargs> .Map </kwargs>
        <out> NoOutcome => ValidationError(C) </out>
        [all-path]

  // SPEC-PROVENANCE:
  // - I-4/E-7: conditional UniqueConstraint uses the constraint violation path.
  claim <k> validate(UniqueCond, true) => .K </k>
        <code> C:Code </code>
        <kwargs> .Map </kwargs>
        <out> NoOutcome => ValidationError(C) </out>
        [all-path]

  // SPEC-PROVENANCE:
  // - E-5/I-5: field-only UniqueConstraint without condition keeps legacy unique errors.
  claim <k> validate(UniqueFieldsLegacy, true) => .K </k>
        <code> C:Code </code>
        <kwargs> .Map </kwargs>
        <out> NoOutcome => LegacyUniqueError </out>
        [all-path]

  // SPEC-PROVENANCE:
  // - I-4/E-7: ExclusionConstraint uses the constraint violation path.
  claim <k> validate(Exclusion, true) => .K </k>
        <code> C:Code </code>
        <kwargs> .Map </kwargs>
        <out> NoOutcome => ValidationError(C) </out>
        [all-path]

  // SPEC-PROVENANCE:
  // - I-6: adding a code parameter must not make non-violations raise.
  claim <k> validate(K:Kind, false) => .K </k>
        <code> C:Code </code>
        <kwargs> .Map </kwargs>
        <out> NoOutcome => Ok </out>
        [all-path]
endmodule


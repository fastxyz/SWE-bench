requires "mini-schema-editor.k"

module SCHEMA-EDITOR-SPEC
  imports MINI-SCHEMA-EDITOR

  // SPEC-PROVENANCE:
  // - E4/E5/E6: generated "_uniq" name identifies the unique_together
  //   constraint among duplicate unique candidates.
  claim
    <k> chooseUnique(true, DEFAULT:Name ; OTHER:Name ; .Names, DEFAULT)
        => .K ... </k>
    <decision> none => delete(DEFAULT) </decision>
    requires OTHER =/=K DEFAULT
    [all-path]

  // SPEC-PROVENANCE:
  // - E4/E5/E6: candidate order must not decide which unique constraint is
  //   dropped; generated-name membership decides it.
  claim
    <k> chooseUnique(true, OTHER:Name ; DEFAULT:Name ; .Names, DEFAULT)
        => .K ... </k>
    <decision> none => delete(DEFAULT) </decision>
    requires OTHER =/=K DEFAULT
    [all-path]

  // SPEC-PROVENANCE:
  // - Existing behavior: once filtering yields exactly one candidate, delete it.
  claim
    <k> chooseUnique(true, ONLY:Name ; .Names, DEFAULT:Name)
        => .K ... </k>
    <decision> none => delete(ONLY) </decision>
    [all-path]

  // SPEC-PROVENANCE:
  // - E7: if multiple candidates remain and no generated name is present, do
  //   not guess; preserve ValueError behavior.
  claim
    <k> chooseUnique(true, A:Name ; B:Name ; .Names, DEFAULT:Name)
        => .K ... </k>
    <decision> none => raise </decision>
    requires A =/=K DEFAULT andBool B =/=K DEFAULT andBool A =/=K B
    [all-path]

  // SPEC-PROVENANCE:
  // - E9/I5: the generated unique-name preference is for unique deletion, not
  //   unrelated non-unique composed-index deletion.
  claim
    <k> chooseUnique(false, DEFAULT:Name ; OTHER:Name ; .Names, DEFAULT)
        => .K ... </k>
    <decision> none => raise </decision>
    requires OTHER =/=K DEFAULT
    [all-path]

  // SPEC-PROVENANCE:
  // - Existing behavior: no candidate means the helper raises.
  claim
    <k> chooseUnique(true, .Names, DEFAULT:Name) => .K ... </k>
    <decision> none => raise </decision>
    [all-path]
endmodule

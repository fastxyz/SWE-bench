requires "mini-autodetector.k"

module AUTODETECTOR-SPEC
  imports MINI-AUTODETECTOR

  // SPEC-PROVENANCE:
  // - E1/E2/E3: AlterField must pick up dependencies when the new field is a FK.
  // - E4/E6: The dependency list is the existing FK dependency helper result.
  claim [ALTER-REL-DEPS]:
    <k> genAlterField(field(true, DEPS:Deps)) => .K </k>
    <ops> .List => ListItem(alterField(field(true, DEPS), DEPS)) </ops>
    [all-path]

  // SPEC-PROVENANCE:
  // - C4/PO4: Non-relational field alterations keep empty relation auto-deps.
  claim [ALTER-NONREL-FRAME]:
    <k> genAlterField(field(false, DEPS:Deps)) => .K </k>
    <ops> .List => ListItem(alterField(field(false, DEPS), .Deps)) </ops>
    [all-path]
endmodule

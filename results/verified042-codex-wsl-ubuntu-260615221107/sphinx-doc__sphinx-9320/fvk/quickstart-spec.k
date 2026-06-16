requires "mini-python-quickstart.k"

module QUICKSTART-SPEC
  imports MINI-PYTHON-QUICKSTART

  // SPEC-PROVENANCE:
  // - E1/E3/E4: existing <root>/conf.py must terminate with status 1.
  // - E2: the legacy replacement prompt is a suspect failure surface, not a
  //   preserved behavior.
  // - E5: no files may be generated for an existing project.
  // CLAIM: QS-EXISTING-ROOT
  claim
    <k> mainInteractive => .K </k>
    <rootConf> true </rootConf>
    <sourceConf> SOURCE:Bool </sourceConf>
    <status> 0 => 1 </status>
    <warning> false => true </warning>
    <replacementPrompt> false </replacementPrompt>
    <generated> false </generated>
    [all-path]

  // SPEC-PROVENANCE:
  // - E6: quickstart's existing guard treats <root>/source/conf.py as an
  //   existing project in the separate-source layout.
  // - E4/E5: the same status-1/no-generation outcome applies.
  // CLAIM: QS-EXISTING-SOURCE
  claim
    <k> mainInteractive => .K </k>
    <rootConf> false </rootConf>
    <sourceConf> true </sourceConf>
    <status> 0 => 1 </status>
    <warning> false => true </warning>
    <replacementPrompt> false </replacementPrompt>
    <generated> false </generated>
    [all-path]

  // SPEC-PROVENANCE:
  // - E7/I6: the non-conflict path is framed as unchanged by this patch.
  //   The reduced model represents the rest of the wizard by generate.
  // CLAIM: QS-NO-CONF-FRAME
  claim
    <k> mainInteractive => .K </k>
    <rootConf> false </rootConf>
    <sourceConf> false </sourceConf>
    <status> 0 </status>
    <warning> false </warning>
    <replacementPrompt> false </replacementPrompt>
    <generated> false => true </generated>
    [all-path]
endmodule

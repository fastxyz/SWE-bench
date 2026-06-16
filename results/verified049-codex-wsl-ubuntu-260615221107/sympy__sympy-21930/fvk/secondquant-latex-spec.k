// K-style claims for secondquant creator LaTeX power grouping.
// Constructed for FVK documentation; not machine-checked in this task.

module SECONDQUANT-LATEX-SPEC
  imports MINI-PYTHON-LATEX

  // SPEC-PROVENANCE:
  // - from_prompt: "It should be correct by adding curly brackets
  //   `{b^\dagger_{0}}^{2}`" => group the whole creator base.
  // - from_code: Creator._latex_power_base supplies the grouped base.
  claim <k> power(Creator(L), Exp(E)) => . </k>
        <out> _ => "{" +String L +String "}^{" +String E +String "}" </out>

  // SPEC-PROVENANCE:
  // - from_code: folded fractional powers also append an outer exponent.
  // - proof-finding F2: the custom hook should win in this branch too.
  claim <k> foldFracPower(Creator(L), P, Q) => . </k>
        <out> _ => "{" +String L +String "}^{" +String P +String "/" +String Q +String "}" </out>

  // SPEC-PROVENANCE:
  // - from_public_tests: direct Bd/Fd LaTeX is unwrapped.
  claim <k> print(Creator(L)) => . </k>
        <out> _ => L </out>

  // SPEC-PROVENANCE:
  // - from_public_tests: existing non-creator superscript behavior is preserved.
  // - from_code: objects without _latex_power_base stay on the legacy path.
  claim <k> power(Other(L), Exp(E)) => . </k>
        <out> _ => L +String "^{" +String E +String "}" </out>

endmodule

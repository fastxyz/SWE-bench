requires "mini-contour-levels.k"

module CONTOUR-LEVELS-SPEC
  imports MINI-CONTOUR-LEVELS

  // SPEC-PROVENANCE:
  // - from_prompt: "for boolean inputs, the only choice that makes sense is
  //   to have a single level at 0.5" => default line contours use [0.5].
  // - from_code: _contour_args records Z.dtype before float64 conversion.
  claim
    <k> processLevels(true, false, true, true, false, HAS:Bool)
      => lineBoolDefault ... </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_hint: "For contourf(bool_array) the natural levels would be
  //   [0, .5, 1]" => default filled contours use three boundaries.
  claim
    <k> processLevels(true, true, true, true, false, HAS:Bool)
      => filledBoolDefault ... </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_docs: "If an int n..." and "If array-like..." => caller-supplied
  //   level arguments remain caller-directed, not replaced by the bool default.
  claim
    <k> processLevels(Z:Bool, F:Bool, false, L:Bool, G:Bool, H:Bool)
      => callerDirectedLevels ... </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: the requested change is an automatic default for bool
  //   arrays, not binary-valued numeric arrays or explicitly locator/log
  //   driven choices.
  claim
    <k> processLevels(Z:Bool, F:Bool, true, L:Bool, G:Bool, H:Bool)
      => legacyAutomaticLevels ... </k>
    requires notBool (Z andBool L andBool notBool G)
    [all-path]
endmodule

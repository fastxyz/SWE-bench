requires "mini-python-datewrap.k"

module DATEWRAP-SPEC
  imports MINI-PYTHON-DATEWRAP
  imports BOOL
  imports STRING

  // SPEC-PROVENANCE:
  // - from_prompt: "protecting spaces didn't happen properly" => spaces
  //   in TeX math chunks must be represented by a TeX spacing command.
  // - from_prompt: workaround replaces '-', ':', and ' ' => protect that
  //   separator family.
  // - from_code: V1 keeps alphaTextSplit before the replacement pipeline.
  // CLAIM-WRAP-IN-TEX
  claim
    <k> wrapInTex(T:String) => expectedWrap(T) </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: "spacing from version 3.3 in a tex format" => date/time
  //   separators must stay visible after TeX wrapping.
  // - conflicts: public tests with raw spaces/colons are SUSPECT legacy
  //   behavior for this bug.
  // CLAIM-PROTECT-SEPARATORS
  claim
    <k> wrapInTex(T:String) => ?OUT:String </k>
    ensures protectsDateSeparators(T, ?OUT)
    [all-path]

  // SPEC-PROVENANCE:
  // - from_docs: formatter usetex option enables TeX math mode.
  // - from_code: built-in formatter TeX branches call _wrap_in_tex.
  // CLAIM-DATEFORMATTER-USETEX
  claim
    <k> dateFormatterResult(true, T:String) => expectedWrap(T) </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_docs: usetex is optional; non-TeX formatting returns plain text.
  // - frame: V1 edits only _wrap_in_tex.
  // CLAIM-DATEFORMATTER-NON-TEX
  claim
    <k> dateFormatterResult(false, T:String) => T </k>
    [all-path]
endmodule

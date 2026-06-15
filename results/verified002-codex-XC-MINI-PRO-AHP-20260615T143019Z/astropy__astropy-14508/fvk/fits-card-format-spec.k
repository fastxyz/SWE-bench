// Constructed for FVK audit; not machine-checked.

requires "mini-fits-card-format.k"

module FITS-CARD-FORMAT-SPEC
  imports MINI-FITS-CARD-FORMAT
  imports INT
  imports STRING

  // SPEC-PROVENANCE:
  // - E5/E6: try Python str(value) before legacy .16G when it fits.
  // - E7/E8: keep normalization and the 20-character token cap.
  // CLAIM: SHORT-REP-PREFERENCE
  claim
    <k> formatFloat(floatView(S:String, Legacy:String))
      => cap20(normalizeExponent(ensureDecimal(normalizeLowerE(S)))) ... </k>
    requires lengthString(normalizeLowerE(S)) <=Int 20
    [all-path]

  // SPEC-PROVENANCE:
  // - E5/E8: when str(value) is longer than the value-token budget, retain the
  //   compact legacy formatting path and existing cap.
  // CLAIM: LEGACY-FALLBACK
  claim
    <k> formatFloat(floatView(S:String, Legacy:String))
      => cap20(normalizeExponent(ensureDecimal(Legacy))) ... </k>
    requires lengthString(normalizeLowerE(S)) >Int 20
    [all-path]

  // SPEC-PROVENANCE:
  // - E4: 0.009125 must not expand to 0.009124999999999999.
  // CLAIM: REPORTED-FLOAT
  claim
    <k> formatFloat(floatView("0.009125", "0.009124999999999999"))
      => "0.009125" ... </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - E2/E3: the reported valid HIERARCH card must be creatable without
  //   truncating the comment.
  // CLAIM: REPORTED-HIERARCH-CARD
  claim
    <k> formatHierarchRadius
      => "HIERARCH ESO IFM CL RADIUS = 0.009125 / [m] radius arround actuator to avoid    " ... </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - E7: lowercase exponent markers should be normalized before output.
  // CLAIM: EXPONENT-NORMALIZATION
  claim
    <k> formatFloat(floatView("5.0022221e-07", "5.0022221000000000E-07"))
      => "5.0022221E-07" ... </k>
    [all-path]
endmodule

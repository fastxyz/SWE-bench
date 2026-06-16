requires "mini-image-lognorm.k"

module IMAGE-LOGNORM-SPEC
  imports MINI-IMAGE-LOGNORM

  // SPEC-PROVENANCE:
  // - from_prompt: "test_huge_range_log is failing ... ValueError"
  //   => the image path must not hand LogNorm an invalid temporary lower
  //      limit when finite huge-range data round a positive vmin to zero.
  // - from_code: colors.py raises "Invalid vmin or vmax" when the transformed
  //   log limits are not finite; for LogNorm this requires vmin > 0.
  // - from_code: image.py already had a LogNorm-specific repair for negative
  //   temporary vmin; the candidate change extends the same repair to zero.
  claim <k> adjustLogVmin(true, S, EPS) => R </k>
    requires EPS >Int 0
    ensures R >Int 0

  // SPEC-PROVENANCE:
  // - from_prompt/test: the failing family includes the exact-zero temporary
  //   lower-limit case caused by round-trip loss over a huge data range.
  claim <k> adjustLogVmin(true, S, EPS) => EPS </k>
    requires EPS >Int 0 andBool S <=Int 0

  // SPEC-PROVENANCE:
  // - from_frame: positive temporary lower limits are already valid for
  //   LogNorm and must not be shifted by the repair.
  claim <k> adjustLogVmin(true, S, EPS) => S </k>
    requires EPS >Int 0 andBool S >Int 0

  // SPEC-PROVENANCE:
  // - from_compatibility: non-LogNorm normalization paths are outside the bug
  //   and the source edit leaves them unchanged.
  claim <k> adjustLogVmin(false, S, EPS) => S </k>
    requires EPS >Int 0
endmodule

requires "mini-hist-kwargs.k"

module HIST-KWARGS-SPEC
  imports MINI-HIST-KWARGS

  // SPEC-PROVENANCE:
  // - from_prompt: "hist() no longer respects range=... when density=True"
  //   => density must not remove the user-provided range.
  // - from_prompt: "range=(0, 1), density=True" with expected endpoints 0, 1
  //   => the explicit range must reach the histogram bin-edge computation.
  // - from_code: V1 uses hist_kwargs['density'] = density, preserving the
  //   existing range entry.
  // CLAIM: hist-range-density
  claim <k> buildHistKwargs(false, 1, range(L:Int, U:Int),
                            true, false, false)
        => kw(true, range(L, U), true, true) </k>
    requires L <Int U

  // SPEC-PROVENANCE:
  // - from_docs: if either density or normed is set, that value is used.
  // - from_code: effective density is bool(density) or bool(normed).
  // CLAIM: hist-range-normed
  claim <k> buildHistKwargs(false, 1, range(L:Int, U:Int),
                            false, true, false)
        => kw(true, range(L, U), true, true) </k>
    requires L <Int U

  // SPEC-PROVENANCE:
  // - from_prompt: "this bug doesn't happen if density=False"
  //   => keep the range-preserving non-density path.
  // CLAIM: hist-range-no-density
  claim <k> buildHistKwargs(false, 1, range(L:Int, U:Int),
                            false, false, false)
        => kw(true, range(L, U), false, false) </k>
    requires L <Int U

  // SPEC-PROVENANCE:
  // - from_code/comment: stacked density is normalized manually after raw
  //   histograms are computed.
  // - from_public_tests: stacked density has existing coverage.
  // CLAIM: hist-stacked-frame
  claim <k> buildHistKwargs(false, 1, range(L:Int, U:Int),
                            true, false, true)
        => kw(true, range(L, U), false, false) </k>
    requires L <Int U

  // SPEC-PROVENANCE:
  // - from_code: multiple non-empty datasets compute common bins with
  //   histogram_bin_edges(..., bin_range, ...) before the per-dataset loop.
  // - from_docs: density still controls count normalization when not stacked.
  // CLAIM: hist-multi-density-frame
  claim <k> buildHistKwargs(false, 2, range(L:Int, U:Int),
                            true, false, false)
        => kw(false, noRange, true, true) </k>
    requires L <Int U
endmodule

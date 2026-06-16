requires "mini-spectral.k"

module MINI-SPECTRAL-SPEC
  imports MINI-SPECTRAL
  imports INT
  imports LIST

  // SPEC-PROVENANCE:
  // - from_prompt: "`np.abs` is not needed" => denominator is signed sum squared.
  // - from_prompt: "mode = 'psd' and scale_by_freq = False" => spectrum branch.
  // - from_code: V1 branch uses window.sum()**2.
  claim <k> normalizePsdSpectrum(RAW:Int, W:List)
        => scaled(RAW, signedSum(W) *Int signedSum(W)) </k>
    requires signedSum(W) =/=Int 0
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: "wrong result for window with negative value" => discriminator.
  // - from_default_domain: exact integer arithmetic models the denominator placement.
  claim <k> normalizePsdSpectrum(1, ListItem(3) ListItem(-1) .List)
        => scaled(1, 4) </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: "`np.abs(window).sum()**2 != window.sum()**2`" => old branch is wrong.
  claim <k> oldNormalizePsdSpectrum(1, ListItem(3) ListItem(-1) .List)
        => scaled(1, 16) </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: "`np.abs(window)**2 == window**2`" for real windows.
  // - from_code: density branch remains result /= Fs; result /= (abs(window)**2).sum().
  claim <k> normalizePsdDensity(1, ListItem(3) ListItem(-1) .List, 5)
        => scaled(1, 50) </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_public_tests: Hann-window relation only covers nonnegative windows.
  // - from_default_domain: for nonnegative coefficients, signed and abs sums match.
  claim <k> normalizePsdSpectrum(1, ListItem(1) ListItem(2) .List)
        => scaled(1, 9) </k>
    [all-path]

  claim <k> oldNormalizePsdSpectrum(1, ListItem(1) ListItem(2) .List)
        => scaled(1, 9) </k>
    [all-path]
endmodule


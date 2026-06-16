requires "mini-xarray-polyval.k"

module MINI-XARRAY-POLYVAL-SPEC
  imports MINI-XARRAY-POLYVAL

  // SPEC-PROVENANCE:
  // - from_prompt: "xr.polyval(azimuth_time.coords[\"azimuth_time\"], polyfit_coefficients)"
  //   should work after the new algorithm uses coord values directly.
  // - from_prompt: traceback subtracts dtype('<m8[ns]') and dtype('<M8[D]').
  // - from_code: repo/xarray/core/computation.py branches on x.dtype.kind == "m"
  //   and passes offset=np.timedelta64(0, "ns") to datetime_to_numeric.
  claim
    <k> ensureNumeric(timedelta64, td(T:Int) , RS:Raws)
      => n(T) , mapConvert(timedelta64, RS) </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_public_hint: the new algorithm evaluates the values of coord.
  // - from_code: datetime64 branch remains relative to the existing epoch
  //   conversion; raw dt(T) is already encoded in epoch nanoseconds in this model.
  claim
    <k> ensureNumeric(datetime64, dt(T:Int) , RS:Raws)
      => n(T) , mapConvert(datetime64, RS) </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_docstring: coord supplies values at which to evaluate the polynomial.
  // - from_code: non-datetime-like values pass through _ensure_numeric unchanged.
  claim
    <k> ensureNumeric(numeric, num(N:Int) , RS:Raws)
      => n(N) , mapConvert(numeric, RS) </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_code: datetime_to_numeric maps datetime-like missing values to NaN.
  // - from_frame_condition: V1 should not change missing-value propagation.
  claim
    <k> ensureNumeric(timedelta64, nat , RS:Raws)
      => nan , mapConvert(timedelta64, RS) </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_docstring: "Evaluate a polynomial at specific values".
  // - from_code: polyval first numericizes coord, then applies Horner's method
  //   over reindexed coefficients.
  claim
    <k> polyval(timedelta64, td(T:Int) , RS:Raws, CS:Coeffs, Max:Int)
      => evalAll(CS, n(T) , mapConvert(timedelta64, RS), Max) </k>
    requires Max >=Int 0
    [all-path]
endmodule

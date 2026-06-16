requires "mini-convert-dx.k"

module MINI-CONVERT-DX-SPEC
  imports MINI-CONVERT-DX

  // SPEC-PROVENANCE:
  // - E-001/E-004/E-006: all-nonfinite bar x data must not leak
  //   StopIteration from first-finite representative selection.
  // - from_code: V1 catches StopIteration and chooses safe_first_element.
  claim [ALL_NONFINITE_NO_STOP]:
    <k> runConvertDx(DXS:Dxs, X0S:Vals, XCS:Vals)
      => widths(mapDelta(firstVal(X0S), firstVal(XCS), DXS)) ... </k>
    requires notBool isEmpty(X0S)
     andBool notBool isEmpty(XCS)
     andBool notBool hasFinite(X0S)
     andBool notBool hasFinite(XCS)
    [all-path]

  // SPEC-PROVENANCE:
  // - E-002/E-003: ax.bar([nan], [nan]) should create nonfinite geometry
  //   rather than raising StopIteration.
  claim [REPRO_SINGLE_NAN]:
    <k> runConvertDx(dx(8) ; .Dxs, nan ; .Vals, nan ; .Vals)
      => widths(nan ; .Vals) ... </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - E-005: keep the first-finite behavior for mixed leading-NaN data.
  claim [MIXED_LEADING_NAN_KEEPS_FIRST_FINITE]:
    <k> runConvertDx(dx(D:Int) ; .Dxs,
                     nan ; finite(X0:Int) ; X0S:Vals,
                     nan ; finite(X:Int) ; XCS:Vals)
      => widths(delta(finite(X0), finite(X), dx(D)) ; .Vals) ... </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - E-008/E-009: empty converted x data is not the requested fix and keeps
  //   the existing direct convert(dx) behavior.
  claim [EMPTY_XCONV_UNCHANGED]:
    <k> runConvertDx(DXS:Dxs, X0S:Vals, .Vals)
      => converted(DXS) ... </k>
    [all-path]
endmodule

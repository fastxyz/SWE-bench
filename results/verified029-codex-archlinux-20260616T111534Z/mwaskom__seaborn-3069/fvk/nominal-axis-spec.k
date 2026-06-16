requires "mini-python-axis.k"

module NOMINAL-AXIS-SPEC
  imports MINI-PYTHON-AXIS
  imports INT
  imports BOOL

  // SPEC-PROVENANCE:
  // - from_prompt: "drawn to +/- 0.5 from the first and last tick" =>
  //   with doubled coordinates, nominal x gets lim(-1, 2 * N - 1).
  // - from_prompt: "`so.Nominal` scales (including inferred ones)" =>
  //   scale kind is nominalScale, independent of whether explicit or inferred.
  claim <k> finalizeAxis(axisState(xAxis, nominalScale, noUserLimit, LO, HI, N, GRID, INV, OLD))
        => axisState(xAxis, nominalScale, noUserLimit, LO, HI, N, false, INV, lim(-1, 2 *Int N -Int 1))
        ... </k>
    requires N >Int 0
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: "drawn to +/- 0.5 from the first and last tick" and
  //   "If on the y axis, the axis is inverted" =>
  //   nominal y gets reversed doubled limits lim(2 * N - 1, -1).
  claim <k> finalizeAxis(axisState(yAxis, nominalScale, noUserLimit, LO, HI, N, GRID, INV, OLD))
        => axisState(yAxis, nominalScale, noUserLimit, LO, HI, N, false, true, lim(2 *Int N -Int 1, -1))
        ... </k>
    requires N >Int 0
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: "A grid is not shown" =>
  //   grid false even when user limits are present.
  // - from_default_domain: explicit Plot.limit values are respected because the
  //   issue describes default drawing behavior, not removal of limit overrides.
  claim <k> finalizeAxis(axisState(xAxis, nominalScale, userLimit, LO, HI, N, GRID, INV, OLD))
        => axisState(xAxis, nominalScale, userLimit, LO, HI, N, false, INV, lim(LO, HI))
        ... </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: "If on the y axis, the axis is inverted" =>
  //   an explicit nominal y limit in normal order is inverted.
  claim <k> finalizeAxis(axisState(yAxis, nominalScale, userLimit, LO, HI, N, GRID, INV, OLD))
        => axisState(yAxis, nominalScale, userLimit, LO, HI, N, false, true, lim(HI, LO))
        ... </k>
    requires LO <=Int HI
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: "If on the y axis, the axis is inverted" =>
  //   an explicit nominal y limit that is already inverted is preserved.
  claim <k> finalizeAxis(axisState(yAxis, nominalScale, userLimit, LO, HI, N, GRID, INV, OLD))
        => axisState(yAxis, nominalScale, userLimit, LO, HI, N, false, true, lim(LO, HI))
        ... </k>
    requires LO >Int HI
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: behavior is specific to Nominal scales =>
  //   non-nominal axes are not changed by the nominal default policy.
  claim <k> finalizeAxis(axisState(AXIS, otherScale, noUserLimit, LO, HI, N, GRID, INV, OLD))
        => axisState(AXIS, otherScale, noUserLimit, LO, HI, N, GRID, INV, OLD)
        ... </k>
    [all-path]
endmodule

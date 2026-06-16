requires "mini-python-figure-pickle.k"

module FIGURE-PICKLE-SPEC
  imports MINI-PYTHON-FIGURE-PICKLE
  imports INT

  // SPEC-PROVENANCE:
  // - E1/E5: high-DPI runtime DPI is backend-applied state and must not be
  //   serialized as permanent logical figure DPI.
  // - E6/E8: _original_dpi is the source's logical DPI for high-DPI paths.
  claim
    <k> getState(fig(L:Int *Int R:Int, L, R, L *Int R))
      => pickle(L, L, L *Int R)
    </k>
    requires L >Int 0 andBool R >Int 1
    [all-path]

  // SPEC-PROVENANCE:
  // - O2: non-high-DPI pickling preserves current _dpi and does not
  //   unconditionally overwrite it with _original_dpi.
  claim
    <k> getState(fig(D:Int, O:Int, 1, T:Int))
      => pickle(D, O, T)
    </k>
    requires D >Int 0
    [all-path]

  // SPEC-PROVENANCE:
  // - E9/E10: dpi_scale_trans is serialized state; after normalization,
  //   __setstate__ must resync the transform from restored _dpi.
  claim
    <k> setState(pickle(P:Int, O:Int, T:Int))
      => fig(P, P, 1, P)
    </k>
    requires P >Int 0
    [all-path]

  // SPEC-PROVENANCE:
  // - E2: same-backend repeated dump/load keeps live DPI stable.
  // - This rules out the legacy L*R*R result.
  claim
    <k> roundTrip(fig(L:Int *Int R:Int, L, R, L *Int R), R)
      => fig(L *Int R, L, R, L *Int R)
    </k>
    requires L >Int 0 andBool R >Int 1
    [all-path]

  // SPEC-PROVENANCE:
  // - O2/O5: ordinary ratio-1 pickling preserves current _dpi and has
  //   transform scale consistent with that restored _dpi.
  claim
    <k> roundTrip(fig(D:Int, O:Int, 1, T:Int), 1)
      => fig(D, D, 1, D)
    </k>
    requires D >Int 0
    [all-path]

  // SPEC-PROVENANCE:
  // - E5: if a high-DPI pickle is loaded without a high-DPI backend, no
  //   backend ratio is reapplied and the base-canvas DPI is logical DPI.
  claim
    <k> roundTrip(fig(L:Int *Int R:Int, L, R, L *Int R), 1)
      => fig(L, L, 1, L)
    </k>
    requires L >Int 0 andBool R >Int 1
    [all-path]
endmodule

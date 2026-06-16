requires "mini-python.k"

module PATCH-LIMITS-SPEC
  imports MINI-PATCH-LIMITS

  // SPEC-PROVENANCE:
  // - from_prompt: "density axis ... is not automatically adjusted to fit the
  //   whole histogram" => a step histogram's full outline must contribute to
  //   data limits.
  // - from_hint: default iter_segments output is "completely wrong for
  //   calculating limits" => path simplification is not allowed for the data
  //   limit iterator.
  // - from_code: V1 calls iter_bezier(simplify=False), which forwards to
  //   iter_segments and Path.cleaned(..., simplify=False, ...).
  claim <k> iterBezier(path(VS), false) => segs(VS) </k>
    ensures coversAllVertices(path(VS), VS)
    [label(UNSIMPLIFIED-COVERAGE)]

  // SPEC-PROVENANCE:
  // - from_code: _update_patch_limits appends curve([0, *dzeros, 1]) for every
  //   unsimplified Bezier segment.
  claim <k> updatePatchLimits(path(VS)) => limitPointList(path(VS)) </k>
    ensures coversAllVertices(path(VS), VS)
    [label(CANDIDATE-POINTS)]

  // SPEC-PROVENANCE:
  // - from_prompt: histtype="step" should autoscale the density axis to fit
  //   the whole histogram.
  // - from_code: step histogram tops are stored as original polygon vertices.
  claim <k> updatePatchLimits(P) => limitPointList(P) </k>
    requires isStepHistPath(P)
    ensures containsMaxDensity(P, limitPointList(P))
    [label(STEP-HIST-MAX)]
endmodule

requires "mini-colorbar-segments.k"

module COLORBAR-SEGMENTS-SPEC
  imports MINI-COLORBAR-SEGMENTS

  // SPEC-PROVENANCE:
  // - from_docs_or_tests: "drawedges : bool / Whether to draw lines at color
  //   boundaries." => disabled drawedges produces no divider segments.
  // - from_code: V1 calls self.dividers.set_segments([]) in the else branch.
  claim
    <k> select(false, E:Extend, N:Int) => emptySegments ... </k>
    requires N >=Int 2
    [all-path]

  // SPEC-PROVENANCE:
  // - from_docs_or_tests: extend='neither' means no extension side.
  // - from_code: non-extended exterior edges are supplied by the outline.
  claim
    <k> select(true, ExtNeither, N:Int) => range(1, N -Int 1) ... </k>
    requires N >=Int 2
    [all-path]

  // SPEC-PROVENANCE:
  // - from_docs_or_tests: extend='min' identifies the data minimum side.
  // - from_prompt/docs: drawedges draws color-boundary lines.
  // - from_code: row 0 is the main-body boundary adjacent to the minimum side.
  claim
    <k> select(true, ExtMin, N:Int) => range(0, N -Int 1) ... </k>
    requires N >=Int 2
    [all-path]

  // SPEC-PROVENANCE:
  // - from_docs_or_tests: extend='max' identifies the data maximum side.
  // - from_prompt/docs: drawedges draws color-boundary lines.
  // - from_code: row N - 1 is the main-body boundary adjacent to the maximum
  //   side.
  claim
    <k> select(true, ExtMax, N:Int) => range(1, N) ... </k>
    requires N >=Int 2
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: "drawedges=True and extend='both' does not draw edges at
  //   extremities" => both extension/body boundaries must be selected.
  // - from_docs_or_tests: extend='both' means both data-end extensions.
  claim
    <k> select(true, ExtBoth, N:Int) => range(0, N) ... </k>
    requires N >=Int 2
    [all-path]
endmodule

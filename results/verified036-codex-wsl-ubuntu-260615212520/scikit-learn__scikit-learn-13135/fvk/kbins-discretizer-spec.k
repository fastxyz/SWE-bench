requires "mini-python.k"

module KBINS-DISCRETIZER-SPEC
  imports MINI-PYTHON-KBINS
  imports K-EQUAL

  // SPEC-PROVENANCE:
  // - from_prompt: unordered centers/edges are fatal for digitize.
  // - from_docs_or_tests: k-means bins are based on nearest 1D centers.
  // - from_code: V1 models np.sort on cluster_centers_[:, 0].
  claim [KMEANS-SORT-CENTERS]:
    <k> sortCenters(CENTERS:List) => SORTED:List ... </k>
    ensures sorted(SORTED) andBool sameBag(CENTERS, SORTED)
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: expected result is no monotonicity error.
  // - from_prompt: unsorted bin_edges are the root failure.
  // - from_code: bin_edges are [col_min, adjacent center midpoints, col_max].
  // - side_condition: KMeans centers lie within the feature min/max range.
  claim [KMEANS-EDGES-MONOTONE]:
    <k> kmeansEdges(MIN:Int, MAX:Int, CENTERS:List) => EDGES:List ... </k>
    requires (MIN <Int MAX)
     andBool inRange(MIN, MAX, CENTERS)
     andBool (length(CENTERS) >=Int 2)
    ensures sorted(EDGES)
    [all-path]

  // SPEC-PROVENANCE:
  // - from_code: transform calls np.digitize with bin_edges[jj][1:].
  // - from_prompt: digitize requires monotonic bins.
  claim [DIGITIZE-SAFE-SUFFIX]:
    <k> digitizeWithBins(tail(EDGES:List)) => true ... </k>
    requires sorted(EDGES)
    [all-path]
endmodule

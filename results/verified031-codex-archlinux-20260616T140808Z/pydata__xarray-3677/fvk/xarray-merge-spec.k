// Abstract K claims for the Dataset.merge(DataArray) audit.
// Constructed, not machine-checked.

requires "mini-xarray-merge.k"

module XARRAY-MERGE-SPEC
  imports MINI-XARRAY-MERGE

  // SPEC-PROVENANCE:
  // - E-001/E-002/E-003: ds.merge(named_da) should follow xr.merge([ds, da]).
  claim
    <k> datasetMerge(DS:Obj, dataArray(N:String), .OSet)
     => core([DS, dataset(N)], none)
    </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - E-006: overwrite-all branch must use normalized DataArray membership.
  claim
    <k> datasetMerge(DS:Obj, dataArray(N:String), vars(dataset(N)))
     => core([DS, dataset(N)], priority(1))
    </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - E-002/E-006: partial overwrite must iterate normalized .items().
  claim
    <k> datasetMerge(DS:Obj, dataArray(N:String), partialVars(dataset(N)))
     => core([DS, mapping("no-overwrite"), mapping("overwrite")], priority(2))
    </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - E-004: unnamed DataArray conversion error is preserved.
  claim
    <k> datasetMerge(DS:Obj, unnamedDataArray, OW:OSet)
     => raises("unnamed-dataarray")
    </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - E-006/E-007: Dataset inputs retain legacy merge behavior.
  claim
    <k> datasetMerge(DS:Obj, dataset(N:String), OW:OSet)
     => legacyDatasetMerge(DS, dataset(N), OW)
    </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - E-006/E-007: mapping inputs retain legacy merge behavior.
  claim
    <k> datasetMerge(DS:Obj, mapping(N:String), OW:OSet)
     => legacyDatasetMerge(DS, mapping(N), OW)
    </k>
    [all-path]
endmodule

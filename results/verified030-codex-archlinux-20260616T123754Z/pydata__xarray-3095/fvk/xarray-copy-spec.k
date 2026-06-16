requires "mini-xarray-copy.k"

module XARRAY-COPY-SPEC
  imports MINI-XARRAY-COPY
  imports INT
  imports BOOL

  // SPEC-PROVENANCE:
  // - from_prompt: "copy(deep=True) casts unicode indices to object"
  //   => deep-copying an IndexVariable with dtype <U*> must preserve that dtype.
  // - from_code: PandasIndexAdapter stores an underlying pandas index dtype
  //   separately from the explicit adapter dtype exposed through xarray.
  claim
    <k> adapterDType(
          copyIndexVariable(indexVar(adapter(object, unicode(N:Int))), true))
        => unicode(N) ... </k>
    requires N >Int 0
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt/hint: "DataArray.copy(deep=False) is not affected"
  //   and the public copy contract requires shallow copies not to alter dtype.
  claim
    <k> adapterDType(
          copyIndexVariable(indexVar(adapter(object, unicode(N:Int))), false))
        => unicode(N) ... </k>
    requires N >Int 0
    [all-path]

  // SPEC-PROVENANCE:
  // - from_docs: copy returns a new object with the same structure; no public
  //   contract permits dtype mutation during copy.
  claim
    <k> adapterDType(
          copyIndexVariable(indexVar(adapter(PANDAS:DType, ADAPTER:DType)),
                            true))
        => ADAPTER ... </k>
    [all-path]
endmodule

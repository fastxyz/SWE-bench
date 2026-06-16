requires "mini-python-api.k"

module DATAARRAY-INTEGRATE-SPEC
  imports MINI-PYTHON-API

  // SPEC-PROVENANCE:
  // - from_prompt: "It should definitely be `coord`" => coord keyword delegates.
  // - from_code: V1 body delegates to Dataset.integrate(coord, datetime_unit).
  claim
    <k> integrateCoord(C:Coord, U:Unit) => delegateDatasetIntegrate(C, U) </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_docs_or_tests: docs and tests use da.integrate("x") => positional calls preserved.
  claim
    <k> integratePositional(C:Coord, U:Unit) => delegateDatasetIntegrate(C, U) </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: "whether it requires a deprecation cycle" => legacy dim may be deprecated.
  // - from_public_test: method("integrate", dim="x") => old keyword compatibility.
  claim
    <k> integrateDim(D:Coord, U:Unit) => warnDelegateDatasetIntegrate(D, U) </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_default_domain: duplicate values for one argument are invalid.
  claim
    <k> integrateBoth(C:Coord, D:Coord, U:Unit) => typeError("cannot specify both 'coord' and 'dim'") </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_default_domain: unrelated unexpected keywords stay errors.
  claim
    <k> integrateUnexpected(K:String) => typeError("unexpected keyword") </k>
    [all-path]
endmodule

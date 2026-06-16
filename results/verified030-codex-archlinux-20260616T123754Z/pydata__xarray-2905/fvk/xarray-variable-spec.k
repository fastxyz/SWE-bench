requires "mini-python.k"

module XARRAY-VARIABLE-SPEC
  imports MINI-XARRAY-COERCION

  // SPEC-PROVENANCE:
  // - E1/E4/E5/E6: arbitrary objects with a values attribute are valid object
  //   payloads and must be preserved.
  // - E7/E9: generic .values access is not the intended contract.
  // - implementation E14/E15: both public paths delegate to as_compatible_data.
  claim [ARBITRARY-VALUES-PRESERVED]:
    <k> asCompatible(arbitraryValuesObject(PAYLOAD:Data))
      => objectArray(arbitraryValuesObject(PAYLOAD)) </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - E2/E3/E4: scalar assignment should store the original object, not
  //   array(PAYLOAD).
  // - E14: Variable.__setitem__ calls as_compatible_data before assignment.
  claim [SCALAR-SETITEM-PRESERVES-ARBITRARY-VALUES-OBJECT]:
    <k> scalarSetitem(arbitraryValuesObject(PAYLOAD:Data))
      => objectArray(arbitraryValuesObject(PAYLOAD)) </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - E8: scalar DataArray construction with HasValues must preserve the object.
  // - E15: DataArray construction calls as_compatible_data.
  claim [SCALAR-DATAARRAY-CONSTRUCT-PRESERVES-ARBITRARY-VALUES-OBJECT]:
    <k> scalarDataArrayConstruct(arbitraryValuesObject(PAYLOAD:Data))
      => objectArray(arbitraryValuesObject(PAYLOAD)) </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - E9/E10/E12/E13: known xarray/pandas containers remain intentional
  //   values-providing containers.
  claim [KNOWN-CONTAINER-UNWRAPS-VALUES]:
    <k> asCompatible(knownValuesContainer(ndarrayData(PAYLOAD:Data)))
      => ndarrayResult(ndarrayData(PAYLOAD)) </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - E10/E11/E13: existing Variable and supported non-NumPy adapter paths are
  //   frame conditions for this fix.
  claim [VARIABLE-AND-ADAPTER-FRAME]:
    <k> asCompatible(variableData(PAYLOAD:Data))
      => variablePayload(PAYLOAD) </k>
    [all-path]

  claim [NON-NUMPY-SUPPORTED-FRAME]:
    <k> asCompatible(nonNumpySupported(PAYLOAD:Data))
      => wrapped(PAYLOAD) </k>
    [all-path]

  // Negative characterization of the pre-V1 defect. This is not an intended
  // postcondition; it documents the behavior the public issue marks SUSPECT.
  claim [PRE-V1-BUG-CHARACTERIZATION]:
    <k> preV1ValuesStep(arbitraryValuesObject(otherObject(PAYLOAD:Data)))
      => ndarrayResult(otherObject(PAYLOAD)) </k>
    [all-path]
endmodule

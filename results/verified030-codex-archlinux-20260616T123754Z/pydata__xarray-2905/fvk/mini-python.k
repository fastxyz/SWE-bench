module MINI-XARRAY-COERCION-SYNTAX
  imports BOOL-SYNTAX

  syntax Data ::= variableData(Data)
                | nonNumpySupported(Data)
                | tupleData(Data)
                | timestampData
                | timedeltaData
                | knownValuesContainer(Data)
                | arbitraryValuesObject(Data)
                | maskedArray(Data)
                | ndarrayData(Data)
                | otherObject(Data)

  syntax Result ::= variablePayload(Data)
                  | wrapped(Data)
                  | objectArray(Data)
                  | ndarrayResult(Data)
                  | datetime64Result
                  | timedelta64Result

  syntax KResult ::= Result

  syntax Exp ::= Result
               | asCompatible(Data)
               | scalarSetitem(Data)
               | scalarDataArrayConstruct(Data)
               | numpyAsarray(Data)
               | maybeWrap(Exp) [strict]
               | preV1ValuesStep(Data)
endmodule

module MINI-XARRAY-COERCION
  imports MINI-XARRAY-COERCION-SYNTAX

  configuration <k> $PGM:Exp </k>

  // Existing early exits in as_compatible_data.
  rule <k> asCompatible(variableData(D)) => variablePayload(D) </k>
  rule <k> asCompatible(nonNumpySupported(D)) => wrapped(D) </k>

  // Existing scalar conversions.
  rule <k> asCompatible(timestampData) => datetime64Result </k>
  rule <k> asCompatible(timedeltaData) => timedelta64Result </k>

  // V1: only known containers are unwrapped through their values payload.
  rule <k> asCompatible(knownValuesContainer(PAYLOAD)) => maybeWrap(numpyAsarray(PAYLOAD)) </k>

  // V1: arbitrary objects with a values attribute are not unwrapped.
  rule <k> asCompatible(arbitraryValuesObject(PAYLOAD)) => maybeWrap(numpyAsarray(arbitraryValuesObject(PAYLOAD))) </k>

  // Other modeled data follows the ordinary NumPy conversion path.
  rule <k> asCompatible(tupleData(D)) => maybeWrap(numpyAsarray(tupleData(D))) </k>
  rule <k> asCompatible(maskedArray(D)) => maybeWrap(numpyAsarray(maskedArray(D))) </k>
  rule <k> asCompatible(ndarrayData(D)) => maybeWrap(numpyAsarray(ndarrayData(D))) </k>
  rule <k> asCompatible(otherObject(D)) => maybeWrap(numpyAsarray(otherObject(D))) </k>

  // Abstract NumPy conversion. The critical discriminator is that arbitrary
  // values objects become object arrays containing the object itself.
  rule <k> numpyAsarray(arbitraryValuesObject(PAYLOAD)) => objectArray(arbitraryValuesObject(PAYLOAD)) </k>
  rule <k> numpyAsarray(PAYLOAD) => ndarrayResult(PAYLOAD) </k> [owise]

  rule <k> maybeWrap(objectArray(D)) => objectArray(D) </k>
  rule <k> maybeWrap(ndarrayResult(D)) => ndarrayResult(D) </k>
  rule <k> maybeWrap(variablePayload(D)) => variablePayload(D) </k>
  rule <k> maybeWrap(wrapped(D)) => wrapped(D) </k>
  rule <k> maybeWrap(datetime64Result) => datetime64Result </k>
  rule <k> maybeWrap(timedelta64Result) => timedelta64Result </k>

  // The two public paths in the issue both delegate to as_compatible_data.
  rule <k> scalarSetitem(D) => asCompatible(D) </k>
  rule <k> scalarDataArrayConstruct(D) => asCompatible(D) </k>

  // Pre-V1 behavior: generic getattr(data, "values", data) unwrapped the
  // arbitrary object's payload. This rule is only used for the negative claim.
  rule <k> preV1ValuesStep(arbitraryValuesObject(PAYLOAD)) => maybeWrap(numpyAsarray(PAYLOAD)) </k>
endmodule

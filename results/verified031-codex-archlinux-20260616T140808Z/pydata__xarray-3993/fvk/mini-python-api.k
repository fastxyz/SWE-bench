module MINI-PYTHON-API-SYNTAX
  imports STRING-SYNTAX

  syntax Coord ::= String | coordPair(String, String)
  syntax Unit ::= noUnit | unit(String)

  syntax Call ::= integrateCoord(Coord, Unit)
                | integratePositional(Coord, Unit)
                | integrateDim(Coord, Unit)
                | integrateBoth(Coord, Coord, Unit)
                | integrateUnexpected(String)

  syntax Outcome ::= delegateDatasetIntegrate(Coord, Unit)
                   | warnDelegateDatasetIntegrate(Coord, Unit)
                   | typeError(String)

  syntax KResult ::= Outcome
endmodule

module MINI-PYTHON-API
  imports MINI-PYTHON-API-SYNTAX

  configuration <k> $PGM:Call </k>

  rule <k> integrateCoord(C, U) => delegateDatasetIntegrate(C, U) </k>
  rule <k> integratePositional(C, U) => delegateDatasetIntegrate(C, U) </k>
  rule <k> integrateDim(D, U) => warnDelegateDatasetIntegrate(D, U) </k>
  rule <k> integrateBoth(C, D, U) => typeError("cannot specify both 'coord' and 'dim'") </k>
  rule <k> integrateUnexpected(K) => typeError("unexpected keyword") </k>
endmodule

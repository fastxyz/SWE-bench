module MINI-PYTHON-AXIS-SYNTAX
  imports INT
  imports BOOL

  syntax AxisName ::= "xAxis" | "yAxis"
  syntax ScaleKind ::= "nominalScale" | "otherScale"
  syntax LimitKind ::= "noUserLimit" | "userLimit"
  syntax Limit ::= "noLimit" | "lim" "(" Int "," Int ")"
  syntax AxisState ::= "axisState" "("
      AxisName , ScaleKind , LimitKind ,
      Int , Int , Int , Bool , Bool , Limit
    ")"
  syntax KItem ::= "finalizeAxis" "(" AxisState ")"
endmodule

module MINI-PYTHON-AXIS
  imports MINI-PYTHON-AXIS-SYNTAX
  imports INT
  imports BOOL

  configuration <k> $PGM:K </k>

  // Doubled coordinates represent half-step categorical limits:
  // -.5 == -1, N - .5 == 2 * N - 1.

  rule <k> finalizeAxis(axisState(xAxis, nominalScale, noUserLimit, LO, HI, N, GRID, INV, OLD))
        => axisState(xAxis, nominalScale, noUserLimit, LO, HI, N, false, INV, lim(-1, 2 *Int N -Int 1))
        ... </k>
    requires N >Int 0

  rule <k> finalizeAxis(axisState(yAxis, nominalScale, noUserLimit, LO, HI, N, GRID, INV, OLD))
        => axisState(yAxis, nominalScale, noUserLimit, LO, HI, N, false, true, lim(2 *Int N -Int 1, -1))
        ... </k>
    requires N >Int 0

  rule <k> finalizeAxis(axisState(xAxis, nominalScale, noUserLimit, LO, HI, N, GRID, INV, OLD))
        => axisState(xAxis, nominalScale, noUserLimit, LO, HI, N, false, INV, OLD)
        ... </k>
    requires N <=Int 0

  rule <k> finalizeAxis(axisState(yAxis, nominalScale, noUserLimit, LO, HI, N, GRID, INV, OLD))
        => axisState(yAxis, nominalScale, noUserLimit, LO, HI, N, false, INV, OLD)
        ... </k>
    requires N <=Int 0

  rule <k> finalizeAxis(axisState(xAxis, nominalScale, userLimit, LO, HI, N, GRID, INV, OLD))
        => axisState(xAxis, nominalScale, userLimit, LO, HI, N, false, INV, lim(LO, HI))
        ... </k>

  rule <k> finalizeAxis(axisState(yAxis, nominalScale, userLimit, LO, HI, N, GRID, INV, OLD))
        => axisState(yAxis, nominalScale, userLimit, LO, HI, N, false, true, lim(HI, LO))
        ... </k>
    requires LO <=Int HI

  rule <k> finalizeAxis(axisState(yAxis, nominalScale, userLimit, LO, HI, N, GRID, INV, OLD))
        => axisState(yAxis, nominalScale, userLimit, LO, HI, N, false, true, lim(LO, HI))
        ... </k>
    requires LO >Int HI

  rule <k> finalizeAxis(axisState(AXIS, otherScale, noUserLimit, LO, HI, N, GRID, INV, OLD))
        => axisState(AXIS, otherScale, noUserLimit, LO, HI, N, GRID, INV, OLD)
        ... </k>

  rule <k> finalizeAxis(axisState(AXIS, otherScale, userLimit, LO, HI, N, GRID, INV, OLD))
        => axisState(AXIS, otherScale, userLimit, LO, HI, N, GRID, INV, lim(LO, HI))
        ... </k>
endmodule

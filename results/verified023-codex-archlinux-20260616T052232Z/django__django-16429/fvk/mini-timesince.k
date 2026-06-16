module MINI-TIMESINCE-SYNTAX
  imports INT-SYNTAX
  imports BOOL-SYNTAX

  syntax TzState ::= "Naive" | "Aware"
  syntax DateTime ::= "dt" "(" Int "," Int "," Int "," Int "," Int "," Int "," TzState ")"
  syntax Command ::= "pivotV0" "(" DateTime "," Int "," Int ")"
                   | "pivotV1" "(" DateTime "," Int "," Int ")"
                   | "remainingV1" "(" DateTime "," DateTime "," Int "," Int ")"
                   | "subOk" "(" DateTime "," DateTime ")"
  syntax Result ::= DateTime | "ok" | "typeError"
  syntax KResult ::= Result
endmodule

module MINI-TIMESINCE
  imports MINI-TIMESINCE-SYNTAX
  imports INT
  imports BOOL

  configuration <k> $PGM:Command </k>

  syntax Int ::= "monthMaxDay" "(" Int ")" [function]
  rule monthMaxDay(1) => 31
  rule monthMaxDay(2) => 28
  rule monthMaxDay(3) => 31
  rule monthMaxDay(4) => 30
  rule monthMaxDay(5) => 31
  rule monthMaxDay(6) => 30
  rule monthMaxDay(7) => 31
  rule monthMaxDay(8) => 31
  rule monthMaxDay(9) => 30
  rule monthMaxDay(10) => 31
  rule monthMaxDay(11) => 30
  rule monthMaxDay(12) => 31

  syntax Int ::= "clampDay" "(" Int "," Int ")" [function]
  rule clampDay(M:Int, D:Int) => D requires 1 <=Int M andBool M <=Int 12 andBool D <=Int monthMaxDay(M)
  rule clampDay(M:Int, D:Int) => monthMaxDay(M) requires 1 <=Int M andBool M <=Int 12 andBool D >Int monthMaxDay(M)

  syntax DateTime ::= "makePivotV0" "(" DateTime "," Int "," Int ")" [function]
  rule makePivotV0(dt(DY:Int, DM:Int, DD:Int, DH:Int, DMin:Int, DS:Int, TZ:TzState), PY:Int, PM:Int)
    => dt(PY, PM, clampDay(PM, DD), DH, DMin, DS, Naive)

  syntax DateTime ::= "makePivotV1" "(" DateTime "," Int "," Int ")" [function]
  rule makePivotV1(dt(DY:Int, DM:Int, DD:Int, DH:Int, DMin:Int, DS:Int, TZ:TzState), PY:Int, PM:Int)
    => dt(PY, PM, clampDay(PM, DD), DH, DMin, DS, TZ)

  syntax Bool ::= "subDefined" "(" DateTime "," DateTime ")" [function]
  rule subDefined(dt(NY:Int, NM:Int, ND:Int, NH:Int, NMin:Int, NS:Int, Naive), dt(DY:Int, DM:Int, DD:Int, DH:Int, DMin:Int, DS:Int, Naive)) => true
  rule subDefined(dt(NY:Int, NM:Int, ND:Int, NH:Int, NMin:Int, NS:Int, Aware), dt(DY:Int, DM:Int, DD:Int, DH:Int, DMin:Int, DS:Int, Aware)) => true
  rule subDefined(dt(NY:Int, NM:Int, ND:Int, NH:Int, NMin:Int, NS:Int, Naive), dt(DY:Int, DM:Int, DD:Int, DH:Int, DMin:Int, DS:Int, Aware)) => false
  rule subDefined(dt(NY:Int, NM:Int, ND:Int, NH:Int, NMin:Int, NS:Int, Aware), dt(DY:Int, DM:Int, DD:Int, DH:Int, DMin:Int, DS:Int, Naive)) => false

  rule <k> pivotV0(D:DateTime, PY:Int, PM:Int) => makePivotV0(D, PY, PM) </k>
  rule <k> pivotV1(D:DateTime, PY:Int, PM:Int) => makePivotV1(D, PY, PM) </k>
  rule <k> subOk(N:DateTime, D:DateTime) => ok </k> requires subDefined(N, D)
  rule <k> subOk(N:DateTime, D:DateTime) => typeError </k> requires notBool subDefined(N, D)
  rule <k> remainingV1(N:DateTime, D:DateTime, PY:Int, PM:Int) => subOk(N, makePivotV1(D, PY, PM)) </k>
endmodule

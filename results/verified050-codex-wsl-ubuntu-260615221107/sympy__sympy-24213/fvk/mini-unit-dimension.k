module MINI-UNIT-DIMENSION-SYNTAX
  imports INT-SYNTAX
  imports BOOL-SYNTAX

  syntax Dim ::= "dimensionless"
               | "length"
               | "time"
               | "velocity"
               | "accelerationTime"
               | "otherDim" "(" Int "," Int ")"

  syntax Dep ::= "dep" "(" Int "," Int ")"

  syntax DimSystem ::= "withDimSystem" | "noDimSystem"

  syntax FD ::= "fd" "(" Int "," Dim ")"
  syntax FDList ::= ".FDList"
                  | FD ";" FDList [right]

  syntax Result ::= "ok" "(" Int "," Dim ")"
                  | "dimensionError" "(" Dim "," Dim ")"

  syntax KItem ::= Result
  syntax KItem ::= "collectAdd" "(" FDList "," DimSystem ")"
                 | "collectAddLoop" "(" Int "," Dim "," FDList "," DimSystem ")"

  syntax Dep ::= depOf(Dim) [function]
  syntax Bool ::= dimEq(Dim, Dim) [function]
                | equivalentDims(DimSystem, Dim, Dim) [function]
                | compatibleDims(DimSystem, Dim, Dim) [function]
                | allCompatible(DimSystem, Dim, FDList) [function]
  syntax Int ::= sumFactors(FDList) [function]
endmodule

module MINI-UNIT-DIMENSION
  imports MINI-UNIT-DIMENSION-SYNTAX
  imports INT
  imports BOOL
  imports K-EQUAL

  configuration <k> $PGM:K </k>

  rule depOf(dimensionless) => dep(0, 0)
  rule depOf(length) => dep(1, 0)
  rule depOf(time) => dep(0, 1)
  rule depOf(velocity) => dep(1, -1)
  rule depOf(accelerationTime) => dep(1, -1)
  rule depOf(otherDim(L, T)) => dep(L, T)

  rule dimEq(D, D) => true
  rule dimEq(D1, D2) => false requires D1 =/=K D2

  rule equivalentDims(withDimSystem, D1, D2) => depOf(D1) ==K depOf(D2)
  rule equivalentDims(noDimSystem, D1, D2) => dimEq(D1, D2)

  rule compatibleDims(DS, D1, D2) => dimEq(D1, D2) orBool equivalentDims(DS, D1, D2)

  rule allCompatible(DS, D, .FDList) => true
  rule allCompatible(DS, D, fd(_, D2) ; REST)
    => compatibleDims(DS, D, D2) andBool allCompatible(DS, D, REST)

  rule sumFactors(.FDList) => 0
  rule sumFactors(fd(F, _) ; REST) => F +Int sumFactors(REST)

  rule <k> collectAdd(fd(F, D) ; REST, DS)
        => collectAddLoop(F, D, REST, DS)
       </k>

  rule <k> collectAddLoop(F, D, .FDList, _)
        => ok(F, D)
       </k>

  rule <k> collectAddLoop(F, D, fd(F2, D2) ; REST, DS)
        => collectAddLoop(F +Int F2, D, REST, DS)
       </k>
       requires compatibleDims(DS, D, D2)

  rule <k> collectAddLoop(_, D, fd(_, D2) ; _, DS)
        => dimensionError(D2, D)
       </k>
       requires notBool compatibleDims(DS, D, D2)
endmodule

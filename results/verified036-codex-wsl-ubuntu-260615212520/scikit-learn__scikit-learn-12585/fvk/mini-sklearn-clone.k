module MINI-SKLEARN-CLONE-SYNTAX
  imports BOOL-SYNTAX
  imports ID-SYNTAX
  imports MAP-SYNTAX

  syntax Obj ::= classObj(Id)
               | estObj(Id, Map)
               | kernelObj(Id, Map)
               | plainObj(Id)

  syntax Action ::= CloneParam(Obj, Bool)
                  | DeepParamEntry(Id, Obj)
                  | CompositionEntry(Id, Obj)

  syntax Outcome ::= ObjResult(Obj)
                   | TypeError
                   | EstimatorClone(Obj)
                   | IncludeOnly(Id, Obj)
                   | IncludeNested(Id, Obj)

  syntax Bool ::= hasGetParams(Obj) [function]
                | isClass(Obj) [function]
                | isEstimatorInstance(Obj) [function]

  syntax Obj ::= deepCopy(Obj) [function]
  syntax KResult ::= Outcome
endmodule

module MINI-SKLEARN-CLONE
  imports MINI-SKLEARN-CLONE-SYNTAX
  imports BOOL
  imports MAP

  configuration <k> $PGM:Action </k>

  rule hasGetParams(classObj(_)) => true
  rule hasGetParams(estObj(_, _)) => true
  rule hasGetParams(kernelObj(_, _)) => true
  rule hasGetParams(plainObj(_)) => false

  rule isClass(classObj(_)) => true
  rule isClass(estObj(_, _)) => false
  rule isClass(kernelObj(_, _)) => false
  rule isClass(plainObj(_)) => false

  rule isEstimatorInstance(O) => hasGetParams(O) andBool notBool isClass(O)

  rule deepCopy(classObj(C)) => classObj(C)
  rule deepCopy(plainObj(P)) => plainObj(P)

  rule <k> CloneParam(O, false) => ObjResult(deepCopy(O)) </k>
    requires notBool isEstimatorInstance(O)

  rule <k> CloneParam(O, true) => TypeError </k>
    requires notBool isEstimatorInstance(O)

  rule <k> CloneParam(O, SAFE) => EstimatorClone(O) </k>
    requires isEstimatorInstance(O)

  rule <k> DeepParamEntry(K, O) => IncludeOnly(K, O) </k>
    requires notBool isEstimatorInstance(O)

  rule <k> DeepParamEntry(K, O) => IncludeNested(K, O) </k>
    requires isEstimatorInstance(O)

  rule <k> CompositionEntry(K, O) => IncludeOnly(K, O) </k>
    requires notBool isEstimatorInstance(O)

  rule <k> CompositionEntry(K, O) => IncludeNested(K, O) </k>
    requires isEstimatorInstance(O)
endmodule

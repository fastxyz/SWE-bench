requires "domains.md"

module MINI-FIELD-COMPARISON-SYNTAX
  imports INT
  imports BOOL
  imports STRING

  syntax Model ::= NoModel | Model(String, Int)
  syntax FieldObj ::= Field(Int, Model)
  syntax HashKey ::= HashKey(Int, Model)

  syntax Bool ::= sameModel(Model, Model) [function]
                | fieldEq(FieldObj, FieldObj) [function]
                | fieldLt(FieldObj, FieldObj) [function]
                | modelSortLt(Model, Model) [function]
                | sameHashKey(FieldObj, FieldObj) [function]
                | setKeepsBoth(FieldObj, FieldObj) [function]

  syntax HashKey ::= fieldHashKey(FieldObj) [function]
endmodule

module MINI-FIELD-COMPARISON
  imports MINI-FIELD-COMPARISON-SYNTAX

  configuration <k> $PGM:K </k>

  rule sameModel(NoModel, NoModel) => true
  rule sameModel(NoModel, Model(_, _)) => false
  rule sameModel(Model(_, _), NoModel) => false
  rule sameModel(Model(L1, I1), Model(L2, I2))
    => (L1 ==String L2) andBool (I1 ==Int I2)

  rule fieldEq(Field(C1, M1), Field(C2, M2))
    => (C1 ==Int C2) andBool sameModel(M1, M2)

  rule fieldHashKey(Field(C, M)) => HashKey(C, M)

  rule sameHashKey(Field(C1, M1), Field(C2, M2))
    => (C1 ==Int C2) andBool sameModel(M1, M2)

  rule fieldLt(Field(C1, M1), Field(C2, M2)) => C1 <Int C2
    requires C1 =/=Int C2
  rule fieldLt(Field(C, M1), Field(C, M2)) => modelSortLt(M1, M2)

  rule modelSortLt(NoModel, NoModel) => false
  rule modelSortLt(NoModel, Model(_, _)) => true
  rule modelSortLt(Model(_, _), NoModel) => false
  rule modelSortLt(Model(L1, I1), Model(L2, I2))
    => (L1 <String L2) orBool ((L1 ==String L2) andBool (I1 <Int I2))

  rule setKeepsBoth(F1, F2) => notBool fieldEq(F1, F2)
endmodule

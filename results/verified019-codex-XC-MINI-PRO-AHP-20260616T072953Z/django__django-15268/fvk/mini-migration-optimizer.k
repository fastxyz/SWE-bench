// Constructed FVK mini-semantics sketch for django__django-15268.
// Not machine-checked in this environment.

module MINI-MIGRATION-OPTIMIZER-SYNTAX
  imports BOOL-SYNTAX
  imports STRING-SYNTAX
  imports LIST

  syntax Option ::= "unique" | "index"
  syntax Op ::= "AT" "(" Option "," String "," String ")"  // option, model, opaque value
              | "FieldRef" "(" String "," String ")"       // model, field
              | "Delete" "(" String ")"
              | "Elidable"
              | "Other" "(" String ")"
  syntax R ::= "FalseR" | "TrueR" | "KeepSelf" | "KeepOther"
  syntax KResult ::= Option | Op | R | Bool | String
endmodule

module MINI-MIGRATION-OPTIMIZER
  imports MINI-MIGRATION-OPTIMIZER-SYNTAX
  imports BOOL
  imports STRING

  configuration <k> $PGM:K </k>

  syntax R ::= "parent" "(" Op "," Op ")" [function]
  syntax R ::= "reduceAT" "(" Op "," Op ")" [function]

  rule parent(AT(O, M, A), AT(O, M, B)) => KeepOther
  rule parent(AT(O, M, A), Delete(M)) => KeepOther
  rule parent(AT(O, M, A), Elidable) => KeepSelf
  rule parent(AT(O, M, A), AT(O2, M2, B)) => TrueR
    requires M =/=String M2
  rule parent(AT(O, M, A), Other(M2)) => TrueR
    requires M =/=String M2
  rule parent(AT(O, M, A), FieldRef(M2, F)) => FalseR
    requires M ==String M2
  rule parent(AT(O, M, A), AT(O2, M, B)) => FalseR
    requires O =/=K O2
  rule parent(AT(O, M, A), Other(M)) => FalseR

  rule reduceAT(Self, Op) => parent(Self, Op)
    requires parent(Self, Op) =/=K FalseR
  rule reduceAT(AT(unique, M, A), AT(index, M, B)) => TrueR
    requires parent(AT(unique, M, A), AT(index, M, B)) ==K FalseR
  rule reduceAT(AT(index, M, A), AT(unique, M, B)) => TrueR
    requires parent(AT(index, M, A), AT(unique, M, B)) ==K FalseR
  rule reduceAT(AT(O, M, A), FieldRef(M, F)) => FalseR
    requires parent(AT(O, M, A), FieldRef(M, F)) ==K FalseR
  rule reduceAT(AT(O, M, A), Other(M)) => FalseR
    requires parent(AT(O, M, A), Other(M)) ==K FalseR
endmodule

// Constructed FVK K-claim sketch for django__django-15268.
// Not machine-checked in this environment.

requires "mini-migration-optimizer.k"

module ALTER-TOGETHER-REDUCE-SPEC
  imports MINI-MIGRATION-OPTIMIZER
  imports K-EQUAL

  // SPEC-PROVENANCE:
  // - INT-7 / F-001 / PO-1: inherited non-False reductions must be preserved.
  claim <k> reduceAT(Self:Op, Op:Op) => R:R ... </k>
    requires parent(Self, Op) =/=K FalseR
     ensures R ==K parent(Self, Op)

  // SPEC-PROVENANCE:
  // - INT-1 / INT-2 / INT-4 / PO-2: unique/index together operations on the
  //   same model are transparent to each other when inherited reduction fails.
  claim <k> reduceAT(AT(unique, M:String, A:String), AT(index, M, B:String)) => TrueR ... </k>
    requires parent(AT(unique, M, A), AT(index, M, B)) ==K FalseR

  claim <k> reduceAT(AT(index, M:String, A:String), AT(unique, M, B:String)) => TrueR ... </k>
    requires parent(AT(index, M, A), AT(unique, M, B)) ==K FalseR

  // SPEC-PROVENANCE:
  // - INT-6 / PO-3: same-option inherited reductions are preserved.
  claim <k> reduceAT(AT(unique, M:String, A:String), AT(unique, M, C:String)) => KeepOther ... </k>

  claim <k> reduceAT(AT(index, M:String, B:String), AT(index, M, D:String)) => KeepOther ... </k>

  // SPEC-PROVENANCE:
  // - INT-3 / F-003 / PO-5: field references remain boundaries.
  claim <k> reduceAT(AT(unique, M:String, A:String), FieldRef(M, F:String)) => FalseR ... </k>

  claim <k> reduceAT(AT(index, M:String, B:String), FieldRef(M, F:String)) => FalseR ... </k>
endmodule

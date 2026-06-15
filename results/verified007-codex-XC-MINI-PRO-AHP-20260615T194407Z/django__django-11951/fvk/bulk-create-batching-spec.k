// Constructed, not machine-checked.
// SPEC-PROVENANCE:
// - from_prompt: "bulk_create batch_size param overrides the compatible batch size calculation"
//   => an explicit positive user batch size must not exceed the backend-compatible cap.
// - from_prompt: "bulk_update properly picks the minimum of two"
//   => effective batch size is min(user batch size, compatible cap) when a user value is provided.
// - from_code: QuerySet._batched_insert() computes max(ops.bulk_batch_size(fields, objs), 1)
//   and slices objs with range(0, len(objs), batch_size).
// - from_code: bulk_create() asserts batch_size is None or positive before calling _batched_insert().

requires "mini-bulk-create.k"

module BULK-CREATE-BATCHING-SPEC
  imports MINI-BULK-CREATE

  claim <k> effectiveBatch(noBatch, C:Int) => C ... </k>
    requires C >=Int 1
    [all-path]

  claim <k> effectiveBatch(userBatch(U:Int), C:Int) => U ... </k>
    requires C >=Int 1 andBool U >Int 0 andBool U <=Int C
    [all-path]

  claim <k> effectiveBatch(userBatch(U:Int), C:Int) => C ... </k>
    requires C >=Int 1 andBool U >Int C
    [all-path]

  claim <k> batchLengths(N:Int, effectiveBatch(noBatch, C:Int)) => ?Batches:List ... </k>
    ensures allLeq(?Batches, C) ==Bool true
      andBool sumList(?Batches) ==Int N
    requires N >=Int 0 andBool C >=Int 1
    [all-path]

  claim <k> batchLengths(N:Int, effectiveBatch(userBatch(U:Int), C:Int)) => ?Batches:List ... </k>
    ensures allLeq(?Batches, C) ==Bool true
      andBool sumList(?Batches) ==Int N
    requires N >=Int 0 andBool C >=Int 1 andBool U >Int 0
    [all-path]
endmodule

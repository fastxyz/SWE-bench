requires "mini-admin-transaction.k"

module CHANGELIST-LIST-EDITABLE-SPEC
  imports MINI-ADMIN-TRANSACTION

  // SPEC-PROVENANCE:
  // - from_prompt: "prevent unexpected states in case of errors" =>
  //   failure inside list_editable processing rolls back the whole submitted
  //   batch of changed-form writes.
  // - from_code: options.py:2014-2024 wraps the changed-form save/log loop
  //   in transaction.atomic(using=router.db_for_write(self.model)).
  // - abstraction: each changed form's save/log sequence is modeled as one
  //   write bundle whose pending writes rollback if an exception escapes.
  claim
    <k> processListEditable(N:Int, F:Int) => .K </k>
    <db> D:Int => D </db>
    <pending> 0 => 0 </pending>
    <inAtomic> false => false </inAtomic>
    <failed> false => true </failed>
    requires N >=Int 0 andBool F >=Int 0 andBool F <Int N
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: transaction handling is added to processing, not a change
  //   to successful list_editable semantics.
  // - from_code: options.py:2015-2024 still performs one save/log sequence
  //   for each changed form.
  // - abstraction: failure index outside the processed range means no bundle
  //   raises, so the atomic block commits exactly N bundles.
  claim
    <k> processListEditable(N:Int, F:Int) => .K </k>
    <db> D:Int => D +Int N </db>
    <pending> 0 => 0 </pending>
    <inAtomic> false => false </inAtomic>
    <failed> false => false </failed>
    requires N >=Int 0 andBool (F <Int 0 orBool F >=Int N)
    [all-path]
endmodule

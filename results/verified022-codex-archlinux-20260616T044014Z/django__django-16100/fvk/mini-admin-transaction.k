// Constructed FVK mini semantics for the Django admin list_editable
// transaction protocol. This is not a full Python or Django semantics.
// It preserves the verified property axis: committed writes vs. writes
// pending inside transaction.atomic().

module MINI-ADMIN-TRANSACTION-SYNTAX
  imports INT-SYNTAX
  imports BOOL-SYNTAX

  syntax Stmt ::= "processListEditable" "(" Int "," Int ")"
                | "processListEditableNoAtomic" "(" Int "," Int ")"
                | "atomic" "{" Stmt "}"
                | "#loop" "(" Int "," Int "," Int ")"
                | "#loopNoAtomic" "(" Int "," Int "," Int ")"
                | "#saveBundle" "(" Int "," Int ")"
                | "#saveBundleNoAtomic" "(" Int "," Int ")"
                | "#commit"
                | "#rollback"
                | "#fail"
endmodule

module MINI-ADMIN-TRANSACTION
  imports MINI-ADMIN-TRANSACTION-SYNTAX
  imports INT
  imports BOOL

  configuration
    <k> $PGM:Stmt </k>
    <db> 0 </db>
    <pending> 0 </pending>
    <inAtomic> false </inAtomic>
    <failed> false </failed>

  rule <k> processListEditable(N, F) => atomic { #loop(0, N, F) } ... </k>
    requires N >=Int 0

  rule <k> atomic { BODY } => BODY ~> #commit ... </k>
       <pending> _ => 0 </pending>
       <inAtomic> false => true </inAtomic>

  rule <k> #loop(I, N, F) => .K ... </k>
    requires I >=Int N

  rule <k> #loop(I, N, F) => #saveBundle(I, F) ~> #loop(I +Int 1, N, F) ... </k>
    requires I <Int N

  // A write bundle represents save_form(), save_model(), save_related(),
  // construct_change_message(), and log_change() for one changed form.
  // The failing case writes to the pending transaction log before the
  // exception is observed, so rollback must also undo the failing bundle.
  rule <k> #saveBundle(I, F) => #fail ... </k>
       <pending> P => P +Int 1 </pending>
    requires I ==Int F

  rule <k> #saveBundle(I, F) => .K ... </k>
       <pending> P => P +Int 1 </pending>
    requires I =/=Int F

  rule <k> #fail ~> REST:K => #rollback ... </k>
       <failed> false => true </failed>
       <inAtomic> true </inAtomic>
    requires true

  rule <k> #fail ~> REST:K => .K ... </k>
       <failed> false => true </failed>
       <inAtomic> false </inAtomic>
    requires true

  rule <k> #commit => .K ... </k>
       <db> D => D +Int P </db>
       <pending> P => 0 </pending>
       <inAtomic> true => false </inAtomic>
       <failed> false </failed>

  rule <k> #rollback => .K ... </k>
       <pending> _ => 0 </pending>
       <inAtomic> true => false </inAtomic>
       <failed> true </failed>

  // Counterfactual pre-fix model used for FINDINGS.md: without atomic(),
  // each bundle increments committed state immediately, so failure after
  // bundle F leaves partial writes committed.
  rule <k> processListEditableNoAtomic(N, F) => #loopNoAtomic(0, N, F) ... </k>
    requires N >=Int 0

  rule <k> #loopNoAtomic(I, N, F) => .K ... </k>
    requires I >=Int N

  rule <k> #loopNoAtomic(I, N, F) => #saveBundleNoAtomic(I, F) ~> #loopNoAtomic(I +Int 1, N, F) ... </k>
    requires I <Int N

  rule <k> #saveBundleNoAtomic(I, F) => #fail ... </k>
       <db> D => D +Int 1 </db>
    requires I ==Int F

  rule <k> #saveBundleNoAtomic(I, F) => .K ... </k>
       <db> D => D +Int 1 </db>
    requires I =/=Int F
endmodule

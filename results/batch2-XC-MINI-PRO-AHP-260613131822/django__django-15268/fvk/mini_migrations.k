// mini_migrations.k
// =============================================================================
// A minimal K semantics ("mini-X") of *exactly* the fragment of Django's
// migration optimizer that the V1 fix for django__django-15268 touches:
//
//   * AlterUniqueTogether / AlterIndexTogether operations,
//   * AlterTogetherOptionOperation.reduce()  (the method the fix adds), and
//   * the optimizer's list-reduction step + fixpoint loop that *consumes*
//     reduce()'s return value (django/db/migrations/optimizer.py).
//
// It models nothing else (no RunSQL, no fields beyond an opaque "blocking" op,
// no managers, etc.) — only what the changed code path actually uses.
//
// CONSTRUCTED, NOT MACHINE-CHECKED (FVK MVP: this file is not run through
// `kompile`/`kprove`; see fvk/PROOF.md for the emitted commands).
// =============================================================================

module MINI-MIGRATIONS-SYNTAX
  imports INT-SYNTAX
  imports BOOL-SYNTAX

  // An option value is a `set of column-tuples` in Django; only EQUALITY on it
  // matters to the optimizer, so we model it as an opaque integer token.
  syntax Val ::= Int

  // The two together-option kinds.  tagU = unique_together, tagI = index_together.
  syntax Tag ::= "tagU" | "tagI"

  // Operations in the fragment:
  //   aut(M, V) = AlterUniqueTogether(name=M, unique_together=V)
  //   ait(M, V) = AlterIndexTogether (name=M, index_together =V)
  //   blk(M)    = ANY other operation that references model M and must NOT be
  //               merged/reordered across it (e.g. AlterField/RemoveField on M).
  //               Stands in for the references_model()==True, non-together case
  //               where reduce() must return False.
  syntax Op  ::= aut(Int, Val) | ait(Int, Val) | blk(Int)

  // An operation list (associative, unit `.Ops`).
  syntax Ops ::= List{Op, ""}

  // reduce()'s three possible return *shapes*, mirrored faithfully:
  //   rList(O) = the Python list  [O]   (a concrete reduction: replace self+O by O)
  //   rTrue    = the bool  True          (independent: may be optimized across)
  //   rFalse   = the bool  False         (blocked: relative order must be kept)
  syntax Reduce ::= "rTrue" | "rFalse" | rList(Op)
endmodule


module MINI-MIGRATIONS
  imports MINI-MIGRATIONS-SYNTAX
  imports INT
  imports BOOL
  imports MAP
  imports K-EQUAL

  // ---------------------------------------------------------------------------
  // 1. DENOTATION:  applyOp / applyOps   (the state_forwards effect)
  // ---------------------------------------------------------------------------
  // The migration state we care about maps key(M, Tag) |-> Val, i.e. the current
  // unique_together / index_together of each model M.  state_forwards of an
  // AlterFooTogether op OVERWRITES exactly one (model, tag) slot; this is the
  // whole observable effect that the optimizer must preserve.
  syntax Key ::= key(Int, Tag)

  syntax Map ::= applyOp(Op, Map) [function, total]
  rule applyOp(aut(M, U), St) => St [ key(M, tagU) <- U ]
  rule applyOp(ait(M, I), St) => St [ key(M, tagI) <- I ]
  rule applyOp(blk(_),    St) => St      // a blocking op's together-effect is nil here

  // applyOps composes operations LEFT TO RIGHT, exactly as a migration runs them.
  syntax Map ::= applyOps(Ops, Map) [function, total]
  rule applyOps(.Ops,    St) => St
  rule applyOps(O Rest,  St) => applyOps(Rest, applyOp(O, St))

  // The (model, tag) slot an op writes; blk writes nothing (we give it a sentinel
  // key that is never equal to a real slot, so it never "absorbs" a together-op).
  syntax Key ::= keyOf(Op) [function, total]
  rule keyOf(aut(M, _)) => key(M, tagU)
  rule keyOf(ait(M, _)) => key(M, tagI)
  rule keyOf(blk(M))    => key(M, tagU)   // unused by applyOp(blk,_)=identity; see Note A

  // ---------------------------------------------------------------------------
  // 2. reduce():  faithful model of AlterTogetherOptionOperation.reduce(self, O)
  //    (composed with ModelOptionOperation.reduce and ModelOperation.reduce).
  //    SELF is always a together-op (aut/ait); O is arbitrary.
  // ---------------------------------------------------------------------------
  syntax Tag  ::= tagOf(Op)   [function]            // partial: defined on together-ops
  rule tagOf(aut(_, _)) => tagU
  rule tagOf(ait(_, _)) => tagI

  syntax Int  ::= modelOf(Op) [function, total]
  rule modelOf(aut(M, _)) => M
  rule modelOf(ait(M, _)) => M
  rule modelOf(blk(M))    => M

  syntax Bool ::= isTogether(Op) [function, total]
  rule isTogether(aut(_, _)) => true
  rule isTogether(ait(_, _)) => true
  rule isTogether(blk(_))    => false

  syntax Reduce ::= reduceB(Op, Op) [function, total]

  // (R1) O is the SAME together-class on the SAME model  -> [O]
  //      <=> ModelOptionOperation.reduce returns [operation].
  rule reduceB(S, O) => rList(O)
    requires isTogether(S) andBool isTogether(O)
     andBool tagOf(S)  ==K  tagOf(O)
     andBool modelOf(S) ==Int modelOf(O)

  // (R2) O is the OTHER together-class on the SAME model -> True   <<< THE V1 FIX >>>
  //      This is the clause added by the patch:
  //        isinstance(operation, AlterTogetherOptionOperation)
  //          and self.name_lower == operation.name_lower
  rule reduceB(S, O) => rTrue
    requires isTogether(S) andBool isTogether(O)
     andBool tagOf(S)  =/=K  tagOf(O)
     andBool modelOf(S) ==Int modelOf(O)

  // (R3) O is on a DIFFERENT model -> True
  //      <=> ModelOperation.reduce: not operation.references_model(self.name).
  rule reduceB(S, O) => rTrue
    requires isTogether(S)
     andBool modelOf(S) =/=Int modelOf(O)

  // (R4) O references the SAME model but is NOT a together-op -> False (blocked)
  //      <=> ModelOperation.reduce returns False (references_model True, no merge).
  rule reduceB(S, O) => rFalse
    requires isTogether(S) andBool notBool isTogether(O)
     andBool modelOf(S) ==Int modelOf(O)

  // ---------------------------------------------------------------------------
  // 3. allCommute(MID, O): every op in list MID can be optimized across O,
  //    i.e. reduceB(Oi, O) == rTrue.  Mirrors the optimizer's
  //        all(op.reduce(other, app_label) is True for op in in_between)
  // ---------------------------------------------------------------------------
  syntax Bool ::= allCommute(Ops, Op) [function, total]
  rule allCommute(.Ops,   _) => true
  rule allCommute(P Rest, O) => (reduceB(P, O) ==K rTrue) andBool allCommute(Rest, O)
endmodule

// optimizer.k  --  mini-Python fragment for django__django-15268
// ===========================================================================
// CONSTRUCTED, NOT MACHINE-CHECKED.  This is a deliberately small "mini-X" K
// semantics covering ONLY the constructs the patched code path uses:
//
//   * AlterTogetherOptionOperation.reduce  -- the classifier the V1 fix edits
//   * MigrationOptimizer.optimize          -- the fixpoint while-loop
//   * AlterTogetherOptionOperation.state_forwards / database_forwards, modelled
//     abstractly as apply() writing one (kind,model) slot of a model-option store
//
// An AlterFooTogether operation is abstracted to the triple it is distinguished
// by for optimization purposes:
//
//     op(KIND, MODEL, VAL)
//        KIND  in {U, I}      U = unique_together , I = index_together
//        MODEL : the model name (lowercased)        ("mymodel", ...)
//        VAL   : the target set, abstracted as an Int token
//
// The whole point of the fix lives in reduce(): for two AlterFooTogether ops it
// returns collapse(later) when they are the *same* kind+model, and commute
// otherwise (different kind on the same model -- the V1 addition -- or a
// different model).  apply() shows why commute is sound: the two kinds write
// disjoint store slots.
// ===========================================================================

module OPTIMIZER-SYNTAX
  imports INT-SYNTAX
  imports BOOL-SYNTAX
  imports ID-SYNTAX

  // ---- operation kinds -----------------------------------------------------
  syntax Kind ::= "U" | "I"                 // unique_together | index_together

  // ---- an abstracted AlterFooTogether operation ----------------------------
  syntax Op ::= "op" "(" Kind "," Id "," Int ")"

  // ---- reduce()'s three possible results -----------------------------------
  //   collapse(OP) ~ Python  [operation]   (a 1-element list)
  //   commute      ~ Python  True          (independent: may be optimized across)
  //   barrier      ~ Python  False         (cannot be optimized across)
  syntax Verdict ::= "collapse" "(" Op ")" | "commute" | "barrier"

  // ---- expressions ---------------------------------------------------------
  syntax Exp ::= Int | Bool | Kind | Id | Op | Verdict
               | "kindOf" "(" Exp ")"   [strict]
               | "modelOf" "(" Exp ")"  [strict]
               | "(" Exp ")"            [bracket]
               > Exp "===" Exp          [seqstrict, left]   // structural equality
               | Exp "=/=" Exp          [seqstrict, left]
               > "not" Exp              [strict]
               > Exp "and" Exp          [seqstrict, left]
               | Exp "or"  Exp          [seqstrict, left]

  syntax KResult ::= Int | Bool | Kind | Id | Op | Verdict

  // ---- statements ----------------------------------------------------------
  syntax Stmt ::= "skip"
                | Id "=" Exp ";"                              [strict(2)]
                | "return" Exp ";"                            [strict]
                | "if" Exp "then" Stmt "else" Stmt            [strict(1)]
                | "while" Exp ":" Stmt                                  // frozen guard
                | Stmt Stmt                                   [left]

  // apply(OP): write OP's value into its (kind,model) store slot
  syntax Stmt ::= "apply" "(" Op ")"   [strict]
endmodule

module OPTIMIZER
  imports OPTIMIZER-SYNTAX
  imports INT
  imports BOOL
  imports MAP

  // <k>     : the computation
  // <store> : program variables                       Id  |-> value
  // <model> : the abstract model-option store    slot(K,M) |-> VAL
  // <out>   : ordered log of database effects emitted by apply()
  configuration
    <k> $PGM:Stmt </k>
    <store> .Map </store>
    <model> .Map </model>
    <out>   .List </out>

  // ----- selectors ----------------------------------------------------------
  rule <k> kindOf(op(K, _, _))  => K ... </k>
  rule <k> modelOf(op(_, M, _)) => M ... </k>

  // ----- structural equality (total, two-valued) ----------------------------
  rule <k> X === X => true  ... </k>
  rule <k> X === Y => false ... </k> requires X =/=K Y
  rule <k> X =/= Y => notBool (X ==K Y) ... </k>

  // ----- booleans -----------------------------------------------------------
  rule <k> not true  => false ... </k>
  rule <k> not false => true  ... </k>
  rule <k> true  and B => B     ... </k>
  rule <k> false and _ => false ... </k>
  rule <k> true  or  _ => true  ... </k>
  rule <k> false or  B => B     ... </k>

  // ----- variables / assignment / sequencing --------------------------------
  rule <k> X:Id => V ... </k> <store> ... X |-> V ... </store>
  rule <k> X = V:KResult ; => skip ... </k>
       <store> STORE => STORE [ X <- V ] </store>
  rule <k> skip S:Stmt => S ... </k>
  rule <k> skip => . ... </k>

  // ----- if -----------------------------------------------------------------
  rule <k> if true  then S else _ => S ... </k>
  rule <k> if false then _ else S => S ... </k>

  // ----- while (keep a frozen guard, re-evaluate a fresh copy) --------------
  rule <k> while B : S => if B then (S while B : S) else skip ... </k>

  // ----- return -------------------------------------------------------------
  rule <k> return V:KResult ; ~> _ => V </k>

  // ----- apply(op(K,M,V)) : write slot (K,M); independent kinds = disjoint --
  //   slot(U, M) and slot(I, M) are DISTINCT map keys, so apply for U and
  //   apply for I touch different bindings -> they commute (Lemma COMMUTE).
  rule <k> apply(op(K, M, V)) => skip ... </k>
       <model> MS => MS [ slot(K, M) <- V ] </model>
       <out> ... .List => ListItem(eff(K, M, V)) </out>

  // slot/eff are inert constructor symbols (no rules): just structure.
  syntax KItem ::= "slot" "(" Kind "," Id ")"
  syntax KItem ::= "eff"  "(" Kind "," Id "," Int ")"
endmodule

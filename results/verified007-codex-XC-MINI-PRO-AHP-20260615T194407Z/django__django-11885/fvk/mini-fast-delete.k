module MINI-FAST-DELETE-SYNTAX
  imports INT-SYNTAX
  imports BOOL-SYNTAX

  syntax Model ::= "Entry" | "PersonFriends" | "OtherModel"
  syntax Pred ::= "created_by" | "updated_by" | "from_id" | "to_id" | "other_pred"
                | Pred "|or|" Pred [left]
  syntax Count ::= "unknown" | "known" "(" Int ")"
  syntax Limit ::= "unbounded" | "bounded" "(" Int ")"
  syntax FD ::= "fd" "(" Model "," Pred "," Count ")"
  syntax FDs ::= ".FDs" | FD ";" FDs [right]

  syntax FDs ::= addFast(FDs, FD, Limit) [function]
  syntax FD ::= combineFD(FD, FD) [function]
  syntax Bool ::= canCombine(FD, FD, Limit) [function]
  syntax Bool ::= paramsOk(Count, Count, Limit) [function]
  syntax Int ::= rawDeleteCount(FDs) [function]

  syntax KResult ::= FDs | FD | Count | Limit
endmodule

module MINI-FAST-DELETE
  imports MINI-FAST-DELETE-SYNTAX
  imports INT
  imports BOOL

  configuration <k> $PGM:K </k>

  rule paramsOk(_, _, unbounded) => true
  rule paramsOk(known(A), known(B), bounded(Max)) => A +Int B <=Int Max
  rule paramsOk(unknown, _, bounded(_)) => false
  rule paramsOk(_, unknown, bounded(_)) => false

  rule canCombine(fd(M, _, C1), fd(M, _, C2), L) => paramsOk(C1, C2, L)
  rule canCombine(fd(M1, _, _), fd(M2, _, _), _) => false
    requires M1 =/=K M2

  rule combineFD(fd(M, P1, known(A)), fd(M, P2, known(B)))
    => fd(M, P1 |or| P2, known(A +Int B))
  rule combineFD(fd(M, P1, _), fd(M, P2, _))
    => fd(M, P1 |or| P2, unknown)
    [owise]

  rule addFast(.FDs, Q, _) => Q ; .FDs
  rule addFast(F ; REST, Q, L) => combineFD(F, Q) ; REST
    requires canCombine(F, Q, L)
  rule addFast(F ; REST, Q, L) => F ; addFast(REST, Q, L)
    requires notBool canCombine(F, Q, L)

  rule rawDeleteCount(.FDs) => 0
  rule rawDeleteCount(_ ; REST) => 1 +Int rawDeleteCount(REST)
endmodule

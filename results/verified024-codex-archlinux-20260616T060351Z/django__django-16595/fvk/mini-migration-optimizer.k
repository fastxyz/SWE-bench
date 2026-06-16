module MINI-MIGRATION-OPTIMIZER-SYNTAX
  imports BOOL-SYNTAX
  imports STRING-SYNTAX

  syntax Field ::= field(String)

  // Operation model for the audited reducer slice. String model/field names
  // represent Django's already-normalized lower-case comparison keys.
  syntax Op ::= alter(String, String, Field, Bool)
              | remove(String, String)
              | rename(String, String, String)
              | other(String)

  syntax Ops ::= ".Ops" [klabel(.Ops)]
               | Op ";" Ops [right]

  syntax ReduceResult ::= ops(Ops) | pass(Bool)

  syntax KItem ::= reduceAlter(Op, Op) [function]
                 | optimizeAlterChain(Ops) [function]
                 | sameField(Op, Op) [function]
                 | sameFieldAlter(Op, Op) [function]

  syntax KResult ::= Field | Op | Ops | ReduceResult | Bool | String
endmodule

module MINI-MIGRATION-OPTIMIZER
  imports MINI-MIGRATION-OPTIMIZER-SYNTAX
  imports BOOL
  imports STRING

  configuration <k> $PGM:K </k>

  rule sameField(alter(M, N, _, _), alter(M, N, _, _)) => true
  rule sameField(alter(M, N, _, _), remove(M, N)) => true
  rule sameField(alter(M, N, _, _), rename(M, N, _)) => true
  rule sameField(_, _) => false [owise]

  rule sameFieldAlter(alter(M, N, _, _), alter(M, N, _, _)) => true
  rule sameFieldAlter(_, _) => false [owise]

  // V1 reducer branch: same-field AlterField followed by AlterField reduces
  // to the later AlterField operation.
  rule <k> reduceAlter(A:Op, B:Op) => ops(B ; .Ops) ... </k>
    requires sameFieldAlter(A, B)

  // Non-modeled fallback: this stands for the pre-existing branches and
  // FieldOperation/Operation fallthrough. It is used only for frame claims.
  rule <k> reduceAlter(A:Op, B:Op) => pass(false) ... </k>
    requires notBool sameFieldAlter(A, B)

  // Abstract repeated optimizer loop over a consecutive same-field AlterField
  // chain. The measure is the number of operations; every first rule use
  // removes one operation.
  rule <k> optimizeAlterChain(
              alter(M, N, _, _) ; alter(M, N, F2, P2) ; REST:Ops
            )
        => optimizeAlterChain(alter(M, N, F2, P2) ; REST) ... </k>

  rule <k> optimizeAlterChain(OP:Op ; .Ops) => OP ; .Ops ... </k>
  rule <k> optimizeAlterChain(.Ops) => .Ops ... </k>
endmodule

module MINI-PYTHON-SPARSE-SYNTAX
  imports INT-SYNTAX

  syntax Algo ::= "lasso_lars" | "lasso_cd" | "lars" | "omp" | "threshold"
  syntax Mode ::= "single" | "parallel"

  syntax Cmd ::= "transform" "(" Algo "," Int ")"
               | "sparseEncode" "(" Algo "," Int "," Mode ")"
               | "worker" "(" Algo "," Int ")"

  syntax Event ::= "CalledSparseEncode" "(" Int ")"
                 | "CalledWorker" "(" Int ")"
                 | "CalledLassoLars" "(" Int ")"
                 | "CalledLasso" "(" Int ")"
                 | "CalledOther" "(" Algo ")"

  syntax Events ::= ".Events" | Event Events
  syntax KResult ::= Int | Algo | Mode | Events
endmodule

module MINI-PYTHON-SPARSE
  imports MINI-PYTHON-SPARSE-SYNTAX
  imports INT

  configuration
    <k> $PGM:Cmd </k>
    <events> .Events </events>

  rule <k> transform(A:Algo, M:Int) => sparseEncode(A, M, single) ... </k>
       <events> Es => CalledSparseEncode(M) Es </events>

  rule <k> sparseEncode(A:Algo, M:Int, single) => worker(A, M) ... </k>
       <events> Es => CalledWorker(M) Es </events>

  rule <k> sparseEncode(A:Algo, M:Int, parallel) => worker(A, M) ... </k>
       <events> Es => CalledWorker(M) Es </events>

  rule <k> worker(lasso_lars, M:Int) => .K ... </k>
       <events> Es => CalledLassoLars(M) Es </events>

  rule <k> worker(lasso_cd, M:Int) => .K ... </k>
       <events> Es => CalledLasso(M) Es </events>

  rule <k> worker(A:Algo, M:Int) => .K ... </k>
       <events> Es => CalledOther(A) Es </events>
    requires A =/=K lasso_lars andBool A =/=K lasso_cd
endmodule

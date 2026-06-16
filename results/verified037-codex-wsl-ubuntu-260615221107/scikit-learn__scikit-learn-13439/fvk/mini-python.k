module MINI-PIPELINE-SYNTAX
  imports INT-SYNTAX

  syntax PVal ::= "pipeline" "(" Int ")"
  syntax PExp ::= PVal
                | "slicePrefix" "(" PExp "," IExp ")" [strict(1,2)]
  syntax IExp ::= Int
                | "pipelineLen" "(" PExp ")" [strict]

  syntax KResult ::= Int | PVal
endmodule

module MINI-PIPELINE
  imports MINI-PIPELINE-SYNTAX
  imports INT
  imports BOOL

  configuration <k> $PGM:K </k>

  // pipeline(N) abstracts a Pipeline whose steps sequence has cardinality N.
  // pipelineLen abstracts Pipeline.__len__, whose intended result is the
  // cardinality of the same steps sequence used by indexing and slicing.
  rule <k> pipelineLen(pipeline(N:Int)) => N ... </k>
    requires N >=Int 0

  // Existing Pipeline slice behavior delegates to self.steps[ind]. For the
  // issue path pipe[:len(pipe)], the relevant slice is a prefix with K == N.
  rule <k> slicePrefix(pipeline(N:Int), K:Int) => pipeline(K) ... </k>
    requires 0 <=Int K andBool K <=Int N
endmodule

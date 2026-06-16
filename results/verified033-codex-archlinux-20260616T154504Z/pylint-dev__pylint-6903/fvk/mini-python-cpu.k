module MINI-PYTHON-CPU-SYNTAX
  imports INT-SYNTAX

  syntax Exp ::= Int
               | "queryShares" "(" Int ")"
               | "queryQuota" "(" Int "," Int ")"
               | "cpuCountSome" "(" Int "," Int ")"
               | "cpuCountNone" "(" Int ")"
               | "autoJobsWithMultiprocessing" "(" Int ")"
               | "autoJobsNoMultiprocessing"

  syntax KResult ::= Int
endmodule

module MINI-PYTHON-CPU
  imports MINI-PYTHON-CPU-SYNTAX
  imports INT
  imports BOOL

  configuration <k> $PGM:Exp </k>

  syntax Int ::= max1Int(Int) [function]
  rule max1Int(N:Int) => N requires N >=Int 1
  rule max1Int(N:Int) => 1 requires N <Int 1

  syntax Int ::= minCpuInt(Int, Int) [function]
  rule minCpuInt(A:Int, B:Int) => A requires A <=Int B
  rule minCpuInt(A:Int, B:Int) => B requires A >Int B

  rule <k> queryShares(SHARES:Int) => max1Int(SHARES /Int 1024) ... </k>
    requires SHARES >Int 0

  rule <k> queryQuota(QUOTA:Int, PERIOD:Int) => max1Int(QUOTA /Int PERIOD) ... </k>
    requires QUOTA >Int 0 andBool PERIOD >Int 0

  rule <k> cpuCountSome(SHARE:Int, HOST:Int) => max1Int(minCpuInt(SHARE, HOST)) ... </k>
    requires HOST >=Int 1

  rule <k> cpuCountNone(HOST:Int) => HOST ... </k>
    requires HOST >=Int 1

  rule <k> autoJobsWithMultiprocessing(CPU:Int) => CPU ... </k>
    requires CPU >=Int 1

  rule <k> autoJobsNoMultiprocessing => 1 ... </k>
endmodule

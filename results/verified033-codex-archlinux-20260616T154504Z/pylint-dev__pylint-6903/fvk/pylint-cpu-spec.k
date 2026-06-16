requires "mini-python-cpu.k"

module PYLINT-CPU-SPEC
  imports MINI-PYTHON-CPU

  // SPEC-PROVENANCE:
  // - from_prompt: "The calculated number should never be 0." => positive count
  // - from_prompt: "cpu.shares ... 2 ... 2/1024 ... cast to an int" => shares path
  // CLAIM: QUERY-SHARES-POSITIVE
  claim
    <k> queryShares(SHARES:Int) => RESULT:Int </k>
    requires SHARES >Int 0
    ensures RESULT >=Int 1
      andBool RESULT ==Int max1Int(SHARES /Int 1024)
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: reported Kubernetes share value 2 must not become worker count 0
  // CLAIM: QUERY-SHARES-REPORTED
  claim
    <k> queryShares(2) => 1 </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: "not sure if the same can happen" for quota/period calculation
  // - from_prompt: "calculated number should never be 0" => same lower bound
  // CLAIM: QUERY-QUOTA-POSITIVE
  claim
    <k> queryQuota(QUOTA:Int, PERIOD:Int) => RESULT:Int </k>
    requires QUOTA >Int 0 andBool PERIOD >Int 0
    ensures RESULT >=Int 1
      andBool RESULT ==Int max1Int(QUOTA /Int PERIOD)
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: fractional cgroup calculations must not round to zero workers
  // CLAIM: QUERY-QUOTA-FRACTIONAL
  claim
    <k> queryQuota(QUOTA:Int, PERIOD:Int) => 1 </k>
    requires QUOTA >Int 0 andBool PERIOD >Int 0 andBool QUOTA <Int PERIOD
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: multiprocessing needs a value > 0
  // - from_code: existing _cpu_count used min(cpu_share, cpu_count); preserve cap
  // CLAIM: CPU-COUNT-SOME-POSITIVE
  claim
    <k> cpuCountSome(SHARE:Int, HOST:Int) => RESULT:Int </k>
    requires HOST >=Int 1
    ensures RESULT >=Int 1
      andBool RESULT ==Int max1Int(minCpuInt(SHARE, HOST))
    [all-path]

  // SPEC-PROVENANCE:
  // - proof_finding: _cpu_count must not propagate a zero helper result
  // CLAIM: CPU-COUNT-ZERO-DEFENSIVE
  claim
    <k> cpuCountSome(0, HOST:Int) => 1 </k>
    requires HOST >=Int 1
    [all-path]

  // SPEC-PROVENANCE:
  // - from_source_help: jobs=0 auto-detects; absent cgroup data keeps fallback
  // CLAIM: CPU-COUNT-NONE-PRESERVES
  claim
    <k> cpuCountNone(HOST:Int) => RESULT:Int </k>
    requires HOST >=Int 1
    ensures RESULT ==Int HOST andBool RESULT >=Int 1
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: --jobs=0 must not pass 0 to multiprocessing
  // CLAIM: AUTO-JOBS-WITH-MP
  claim
    <k> autoJobsWithMultiprocessing(CPU:Int) => RESULT:Int </k>
    requires CPU >=Int 1
    ensures RESULT ==Int CPU andBool RESULT >=Int 1
    [all-path]

  // SPEC-PROVENANCE:
  // - from_code: existing no-multiprocessing fallback sets jobs to 1
  // CLAIM: AUTO-JOBS-NO-MP
  claim
    <k> autoJobsNoMultiprocessing => 1 </k>
    [all-path]
endmodule

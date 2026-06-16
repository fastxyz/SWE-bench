requires "mini-java-arithmetic.k"

module ARITHMETIC-POST-AGGREGATOR-SPEC
  imports MINI-JAVA-ARITHMETIC
  imports K-EQUAL

  // SPEC-PROVENANCE:
  // - from_prompt: "Support Post aggregation function pow(f1,f2)" => lookup accepts "pow".
  // - from_code: POW("pow") is inserted into LOOKUP_MAP by the existing enum loop.
  claim <k> lookup("pow") => POW ... </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: "equivalent to Math.pow()" => pairwise POW dispatches to Math.pow.
  // - from_code: POW.compute returns Math.pow(lhs, rhs).
  claim <k> opCompute(POW, A:DVal, B:DVal) => mathPow(A, B) ... </k>
    requires A =/=K null andBool B =/=K null
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: "pow(f1,f2)" => two-field pow computes Math.pow(f1, f2).
  // - from_docs: arithmetic post-aggregator uses floating-point arithmetic.
  claim <k> compute(POW, cons(A:DVal, cons(B:DVal, nil))) => mathPow(A, B) ... </k>
    requires A =/=K null andBool B =/=K null
    [all-path]

  // SPEC-PROVENANCE:
  // - from_docs: arithmetic post-aggregator applies the function to fields left to right.
  // - from_code: compute updates retVal by op.compute(retVal, nextVal) for each next field.
  claim <k> compute(POW, cons(A:DVal, cons(B:DVal, cons(C:DVal, nil))))
        => mathPow(mathPow(A, B), C) ... </k>
    requires A =/=K null andBool B =/=K null andBool C =/=K null
    [all-path]

  // SPEC-PROVENANCE:
  // - from_code_comment: arithmetic operators return null if any value is null.
  claim <k> compute(POW, cons(A:DVal, cons(null, nil))) => null ... </k>
    requires A =/=K null
    [all-path]

  // SPEC-PROVENANCE:
  // - from_cache_correctness: pow(a,b) and pow(b,a) are not generally equal.
  // - from_code: preserveFieldOrderInCacheKey(POW) returns true.
  claim <k> cacheMode(POW) => Preserve ... </k>
    [all-path]
endmodule

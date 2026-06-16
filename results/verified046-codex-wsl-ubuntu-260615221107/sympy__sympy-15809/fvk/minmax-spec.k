requires "mini-python.k"

module MINMAX-SPEC
  imports MINI-PYTHON

  // SPEC-PROVENANCE:
  // - from_prompt: "have them return `oo`" for zero-argument Min.
  // - from_code: Min.identity is S.Infinity, modeled as oo.
  claim
    <k> construct(MinCls, .Args) => oo </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: "and `-oo`, respectively" for zero-argument Max.
  // - from_code: Max.identity is S.NegativeInfinity, modeled as negOo.
  claim
    <k> construct(MaxCls, .Args) => negOo </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: issue names only zero-argument behavior.
  // - from_docs_or_tests: Min/Max are existing public constructors for
  //   non-empty minimum/maximum behavior.
  // - from_code: V1 changes only the initial empty-args branch; after that
  //   branch, the non-empty constructor path is unchanged.
  claim
    <k> construct(C:Class, consArg(A:Id, REST:Args))
      => tailResult(C, consArg(A, REST))
    </k>
    [all-path]
endmodule


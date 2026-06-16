requires "mini-python.k"

module PIPELINE-LEN-SPEC
  imports MINI-PIPELINE
  imports INT
  imports BOOL

  // Claim LEN.
  // SPEC-PROVENANCE:
  // - from_prompt: "Pipeline should implement __len__" => len(pipe) must be defined.
  // - from_docs_or_tests: "steps : list" and "List of (name, transform) tuples" =>
  //   the length is the cardinality of Pipeline.steps.
  // - from_default_domain: Python len(x) for a sequence-like object returns its
  //   element count as a non-negative integer.
  // - from_code: V1 implements return len(self.steps), matching the same steps
  //   sequence that __getitem__ indexes and slices.
  claim
    <k> pipelineLen(pipeline(N:Int)) => N ... </k>
    requires N >=Int 0
    [all-path]

  // Claim FULL-SLICE-AFTER-LEN.
  // SPEC-PROVENANCE:
  // - from_prompt: "pipe[:len(pipe)] raises an error" => the full-prefix slice
  //   should become evaluable once len(pipe) is defined.
  // - from_code: Pipeline.__getitem__ delegates slices to self.steps[ind] with
  //   step None or 1, so a prefix of length len(self.steps) preserves all steps.
  // - from_default_domain: sequence prefix slicing with stop equal to sequence
  //   length returns the complete sequence.
  claim
    <k> slicePrefix(pipeline(N:Int), pipelineLen(pipeline(N:Int))) => pipeline(N) ... </k>
    requires N >=Int 0
    [all-path]
endmodule

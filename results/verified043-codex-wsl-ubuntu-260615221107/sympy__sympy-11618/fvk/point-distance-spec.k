requires "mini-python.k"

module POINT-DISTANCE-SPEC
  imports MINI-POINT-DISTANCE

  // SPEC-PROVENANCE:
  // - from_prompt: "The 3rd dimension is being ignored" => iterate until both
  //   coordinate lists are exhausted.
  // - from_prompt: "instead of sqrt(5)" => missing coordinates contribute as 0.
  // - from_docs: "A point in a n-dimensional Euclidean space" => arbitrary
  //   finite coordinate lists are in the contract.
  claim [POINT-DISTANCE-GENERAL]:
    <k> distance(point(AS:Ints), point(BS:Ints))
        => sqrt(sumsq(AS, BS)) </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: "Point(2,0).distance(Point(1,0,2))" => concrete regression.
  // - from_prompt: "instead of sqrt(5)" => expected result.
  claim [POINT-DISTANCE-REPORTED]:
    <k> distance(point(2 ; 0 ; .Ints), point(1 ; 0 ; 2 ; .Ints))
        => sqrt(5) </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_docs/examples: same-dimensional point distance examples must remain
  //   unchanged.
  // - from_code: when both lists have equal length, no zero-fill branch is used.
  claim [POINT-DISTANCE-SAME-DIM-FRAME]:
    <k> distance(point(A:Int ; B:Int ; .Ints), point(C:Int ; D:Int ; .Ints))
        => sqrt(((A -Int C) *Int (A -Int C)) +Int
                ((B -Int D) *Int (B -Int D))) </k>
    [all-path]
endmodule

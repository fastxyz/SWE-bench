requires "mini-sympy-array.k"

module ARRAY-SIZE-SPEC
  imports MINI-SYMPY-ARRAY
  imports INT

  // SPEC-PROVENANCE:
  // - from_prompt: "`len` of rank-0 arrays returns 0" => the old result is the bug.
  // - from_prompt: "correct value should be one" => scalar rank-0 size is 1.
  // - from_prompt: "number of elements of the iterator" => one scalar element is counted.
  // - from_numpy_reference: "numpy.asarray(1).size 1" => size convention for scalar arrays.
  // - from_code: `NDimArray.__len__` returns the cached constructor `_loop_size`.
  claim <k> len(mkDenseImmutable(.Dims, scalar(X:Int))) => 1 ... </k> [all-path]

  // SPEC-PROVENANCE:
  // - same public intent as the immutable dense claim.
  // - from_code: mutable dense arrays compute `_loop_size` in their own constructor.
  claim <k> len(mkDenseMutable(.Dims, scalar(X:Int))) => 1 ... </k> [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: the obligation is on `NDimArray.__len__`, shared by storage variants.
  // - from_code: sparse arrays cache `_loop_size` separately and sparse iteration ranges over it.
  claim <k> len(mkSparseImmutable(.Dims, scalar(X:Int))) => 1 ... </k> [all-path]

  // SPEC-PROVENANCE:
  // - same public intent as the immutable sparse claim.
  // - from_code: mutable sparse arrays compute `_loop_size` in their own constructor.
  claim <k> len(mkSparseMutable(.Dims, scalar(X:Int))) => 1 ... </k> [all-path]

  // SPEC-PROVENANCE:
  // - from_docstring: `__len__` returns the number of elements in the array.
  // - from_existing_public_tests: non-rank-0 examples such as shape `(3, 3)` keep product length.
  // - from_default_domain: shape dimensions are nonnegative integer extents.
  claim <k> len(mkDenseImmutable(D1:Int : D2:Int : .Dims, flat(N:Int))) => D1 *Int D2 ... </k>
    requires D1 >=Int 0 andBool D2 >=Int 0
    [all-path]
endmodule

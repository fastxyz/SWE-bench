requires "mini-python-sparse.k"

module SPARSE-CODING-SPEC
  imports MINI-PYTHON-SPARSE

  // SPEC-PROVENANCE:
  // - from_prompt: "`SparseCoder` doesn't expose `max_iter`" =>
  //   transform-level iteration control must reach the backend.
  // - from_prompt: "`max_iter` is ... not passed to `LassoLars`" =>
  //   lasso_lars must construct LassoLars with the same M.
  claim
    <k> transform(lasso_lars, M:Int) => .K </k>
    <events>
      .Events
      => CalledLassoLars(M) CalledWorker(M) CalledSparseEncode(M) .Events
    </events>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: "just fixing it to pass to LassoLars seems sensible" =>
  //   direct sparse_encode single-worker path must preserve M.
  claim
    <k> sparseEncode(lasso_lars, M:Int, single) => .K </k>
    <events>
      .Events
      => CalledLassoLars(M) CalledWorker(M) .Events
    </events>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_code: sparse_encode also calls _sparse_encode through Parallel =>
  //   the parallel worker path must preserve M.
  claim
    <k> sparseEncode(lasso_lars, M:Int, parallel) => .K </k>
    <events>
      .Events
      => CalledLassoLars(M) CalledWorker(M) .Events
    </events>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_code: lasso_cd already used Lasso(max_iter=max_iter) =>
  //   preserve coordinate-descent forwarding.
  claim
    <k> transform(lasso_cd, M:Int) => .K </k>
    <events>
      .Events
      => CalledLasso(M) CalledWorker(M) CalledSparseEncode(M) .Events
    </events>
    [all-path]
endmodule

requires "mini-nanops.k"

module MINI-NANOPS-SPEC
  imports MINI-NANOPS

  // SPEC-PROVENANCE:
  // - from_prompt: "sum with min_count errors when passing more than one dim"
  //   => multi-axis reductions with min_count are in-domain.
  // - from_prompt: "`mask.shape[axis]` with `np.take(a.shape, axis).prod()`"
  //   => total reduced elements for several axes is the product of those sizes.
  // - from_docs: "If fewer than min_count non-NA values are present the result
  //   will be NA" => null iff valid_count < min_count.
  // - from_code: V1 computes count = np.take(mask.shape, axis).prod() and
  //   null_mask = (count - mask.sum(axis) - min_count) < 0.
  claim <k> maybeNull(D0:Int *Int D1:Int, NULLS:Int, MIN:Int) => null </k>
    requires D0 >Int 0
     andBool D1 >Int 0
     andBool NULLS >=Int 0
     andBool NULLS <=Int D0 *Int D1
     andBool MIN >=Int 0
     andBool D0 *Int D1 -Int NULLS <Int MIN
    [all-path]

  // SPEC-PROVENANCE:
  // - same ledger entries as MULTI-AXIS-NULL.
  claim <k> maybeNull(D0:Int *Int D1:Int, NULLS:Int, MIN:Int) => keep </k>
    requires D0 >Int 0
     andBool D1 >Int 0
     andBool NULLS >=Int 0
     andBool NULLS <=Int D0 *Int D1
     andBool MIN >=Int 0
     andBool D0 *Int D1 -Int NULLS >=Int MIN
    [all-path]

  // SPEC-PROVENANCE:
  // - from_docs: existing one-axis min_count behavior must be preserved.
  // - from_code: np.take(mask.shape, axis).prod() equals mask.shape[axis] for
  //   a single integer axis.
  claim <k> maybeNull(D0:Int, NULLS:Int, MIN:Int) => null </k>
    requires D0 >Int 0
     andBool NULLS >=Int 0
     andBool NULLS <=Int D0
     andBool MIN >=Int 0
     andBool D0 -Int NULLS <Int MIN
    [all-path]

  // SPEC-PROVENANCE:
  // - same ledger entries as SINGLE-AXIS-NULL.
  claim <k> maybeNull(D0:Int, NULLS:Int, MIN:Int) => keep </k>
    requires D0 >Int 0
     andBool NULLS >=Int 0
     andBool NULLS <=Int D0
     andBool MIN >=Int 0
     andBool D0 -Int NULLS >=Int MIN
    [all-path]
endmodule

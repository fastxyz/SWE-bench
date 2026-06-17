requires "mini-kahane-prefix.k"

module KAHANE-PREFIX-SPEC
  imports MINI-KAHANE-PREFIX

  // SPEC-PROVENANCE:
  // - from_prompt: "Leading gamma matrices without contractions should be
  //   unaffected" => the prefix P must be prepended to each branch without
  //   reversing it.
  // - from_prompt: "the insertion loop is just backward" => the proof target is
  //   the restoration loop direction.
  // - from_code: V1 iterates from first_dum_pos - 1 down to 0 while inserting
  //   each free_pos[i] at branch position 0.
  claim <k> restoreOneFixed(P:Idxs, RI:Idxs) => append(P, RI) </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: leading matrices should be unaffected for the whole product.
  // - from_code: resulting_indices contains one list per additive result
  //   branch, so the prefix must be restored to every branch.
  claim <k> restoreLeading(P:Idxs, BS:Branches) => mapPrefix(P, BS) </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt example:
  //   G(rho)*G(sigma)*G(mu)*G(-mu) should simplify to
  //   4*G(rho)*G(sigma).
  claim
    <k>
      restoreLeading(
        idx(rho, idx(sigma, .Idxs)),
        branch(.Idxs, .Branches)
      )
      => branch(idx(rho, idx(sigma, .Idxs)), .Branches)
    </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - diagnostic from_prompt: the old insertion loop prepended leading terms in
  //   reverse order. This claim captures the legacy failure, not desired
  //   behavior.
  claim
    <k>
      legacyRestoreLeading(
        idx(rho, idx(sigma, .Idxs)),
        branch(.Idxs, .Branches)
      )
      => branch(idx(sigma, idx(rho, .Idxs)), .Branches)
    </k>
    [all-path]
endmodule

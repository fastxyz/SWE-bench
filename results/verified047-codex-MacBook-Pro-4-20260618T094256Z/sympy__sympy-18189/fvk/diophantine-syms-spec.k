requires "verification.k"

module DIOPHANTINE-SYMS-SPEC
  imports VERIFICATION

  // Claim C1: DIO-CANONICAL-OMITTED-SYMS
  // SPEC-PROVENANCE:
  // - from_docs_or_tests: "The elements of the tuple ... are arranged according
  //   to the alphabetic ordering of the variables." => no supplied syms uses the
  //   canonical variable order.
  // - from_prompt: "If permute is set to True then permutations ... will be
  //   returned when applicable." => PERM is part of the canonical result.
  // - from_code: syms normalization recurses by calling diophantine with syms
  //   omitted.
  // - conflicts: none for V1; full solver internals are abstracted by canonical.
  claim
    <k> diophantine(EQ:Equation, P:Param, noSyms, PERM:Bool)
         => canonical(EQ, P, PERM) ... </k>
    [all-path]

  // Claim C2: DIO-SYMS-REORDER-FORWARDS-PERMUTE
  // SPEC-PROVENANCE:
  // - from_prompt: "incomplete results depending on syms order with
  //   permute=True" => changing syms order must not drop permuted solutions.
  // - from_prompt: "permute=True is lost when diophantine calls itself" =>
  //   recursive solve must receive the caller's PERM value.
  // - from_docs_or_tests: "syms is an optional list of symbols which determines
  //   the order of the elements in the returned tuple" => final result is a
  //   tuple-position remap of the canonical solve.
  // - from_code: V1 uses diophantine(eq, param, permute=permute) in the syms
  //   reordering branch.
  // - conflicts: pre-fix behavior hard-coded the recursive PERM to false.
  claim
    <k> diophantine(EQ:Equation, P:Param, SYMS:SymList, PERM:Bool)
         => reorder(vars(EQ), SYMS, canonical(EQ, P, PERM)) ... </k>
    requires completeSyms(SYMS, vars(EQ)) andBool needsReorder(SYMS, vars(EQ))
    [all-path]

  // Claim C3: DIO-SYMS-SAME-ORDER-FRAME
  // SPEC-PROVENANCE:
  // - from_prompt: the reported defect appears only when syms order differs.
  // - from_docs_or_tests: syms matching canonical variable order should leave
  //   the canonical solve result unchanged.
  // - from_code: V1 does not modify the same-order branch.
  // - conflicts: none.
  claim
    <k> diophantine(EQ:Equation, P:Param, SYMS:SymList, PERM:Bool)
         => canonical(EQ, P, PERM) ... </k>
    requires completeSyms(SYMS, vars(EQ)) andBool sameOrder(SYMS, vars(EQ))
    [all-path]

  // Claim C4: DIO-ISSUE-PERMUTE-TRUE-NM
  // SPEC-PROVENANCE:
  // - from_prompt: diophantine(n**4 + m**4 - 2**4 - 3**4, syms=(n,m),
  //   permute=True) should not return only {(3, 2)}; it should preserve the
  //   complete signed/permuted solution set.
  // - from_prompt: syms=(m,n), permute=True displays the eight-solution set.
  // - from_code: V1 forwards true through the recursive call, then remaps.
  // - conflicts: pre-fix output {(3, 2)} is marked SUSPECT legacy behavior.
  claim
    <k> diophantine(pow4_mn_2_3, tparam, nm, true)
         => pow4_signed_nm ... </k>
    [all-path]

  // Claim C5: DIO-ISSUE-PERMUTE-FALSE-FRAME
  // SPEC-PROVENANCE:
  // - from_prompt: the fix concerns permute=True completeness.
  // - from_code: forwarding a symbolic PERM must preserve PERM=false behavior
  //   in the same branch rather than broadening all calls.
  // - conflicts: none.
  claim
    <k> diophantine(pow4_mn_2_3, tparam, nm, false)
         => pow4_base_nm ... </k>
    [all-path]
endmodule

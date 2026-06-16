requires "mini-python.k"

module AUTODOC-MODULE-ALL-SPEC
  imports MINI-PYTHON-AUTODOC

  // SPEC-PROVENANCE:
  // - from_source: inspect.getall() represents absent/ignored __all__ as None.
  // - from_public_test: ignore-module-all keeps implicit member behavior.
  // Claim: NO-ALL-BRANCH
  claim
    <k> getObjectMembers(true, noAll, MS:Members, SELECTED:Members)
        => result(true, MS) </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: empty __all__ must not be ignored.
  // - from_source: valid __all__ is a list/tuple sequence, possibly empty.
  // Claim: EXPLICIT-ALL-BRANCH
  claim
    <k> getObjectMembers(true, exports(NS:Names), MS:Members, SELECTED:Members)
        => result(false, markSkipped(NS, MS)) </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: "__all__ = []" with ":members:" should show no entries.
  // - modeled boundary: exports(.Names) is explicit empty __all__, not noAll.
  // Claim: EMPTY-ALL-BRANCH
  claim
    <k> getObjectMembers(true, exports(.Names), MS:Members, SELECTED:Members)
        => result(false, markSkipped(.Names, MS)) </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: expected behavior is "No entries should be shown".
  // - from_source: filter_members sets keep = False for ObjectMember.skipped.
  // Claim: EMPTY-ALL-FILTER
  claim
    <k> filterMembers(markSkipped(.Names, MS:Members))
        => .Members </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - frame condition: explicit selected members are outside the bug fix.
  // Claim: EXPLICIT-MEMBERS-FRAME
  claim
    <k> getObjectMembers(false, AS:AllState, MS:Members, SELECTED:Members)
        => result(false, SELECTED) </k>
    [all-path]
endmodule

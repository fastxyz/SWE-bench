requires "mini-autodoc.k"

module AUTODOC-PRIVATE-MEMBERS-SPEC
  imports MINI-AUTODOC

  // SPEC-PROVENANCE:
  // - from_prompt: "private-members option does not allow specification of which private members"
  //   => the option argument must be represented as a selector list, not collapsed to True.
  claim <k> parseMembers(optCsv(ListItem("_one") ListItem("_two"))) => selNames(ListItem("_one") ListItem("_two")) </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_docs: "Setting None or True ... is equivalent to giving only the option name"
  //   => bare and True values still mean all private members.
  claim <k> parseMembers(optBare) => selAll </k>
    [all-path]

  claim <k> parseMembers(optTrue) => selAll </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: "take arguments, similarly to how :members: currently works"
  // - from_existing_special_members_behavior: named special members are merged into members
  //   => explicit private names become explicit member requests when members is absent.
  claim <k> mergeMembers(membersAbsent, selNames(ListItem("_one"))) => membersList(ListItem("_one")) </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_members_semantics: explicit members list order is preserved and extended without duplicates
  //   => private member names augment, but do not duplicate, existing explicit members.
  claim <k> mergeMembers(membersList(ListItem("public") ListItem("_one")),
                         selNames(ListItem("_one") ListItem("_two")))
        => membersList(ListItem("public") ListItem("_one") ListItem("_two")) </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_docs: "members" as a bare option documents all members
  // - frame_condition: a selector modifier must not replace membersAll with a finite list
  //   => when :members: is ALL, private-members remains a filter modifier.
  claim <k> mergeMembers(membersAll, selNames(ListItem("_one"))) => membersAll </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: "only like to document 1 or 2"
  //   => in all-members mode a private list keeps a listed private documented member.
  claim <k> keepPrivate(true, selNames(ListItem("_one")),
                        member("_one", true, true, false, false, false)) => true </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: "only like to document 1 or 2"
  //   => in all-members mode a private list rejects unlisted private documented members.
  claim <k> keepPrivate(true, selNames(ListItem("_one")),
                        member("_two", true, true, false, false, false)) => false </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_legacy_docs: bare private-members includes private members
  //   => the bare selector still keeps all eligible private documented members.
  claim <k> keepPrivate(true, selAll,
                        member("_two", true, true, false, false, false)) => true </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_existing_filter_order: exclude-members removes members before private filtering
  //   => exclusion precedence is preserved for selected private names.
  claim <k> keepPrivate(true, selNames(ListItem("_one")),
                        member("_one", true, true, false, true, false)) => false </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_existing_filter_order: mocked objects are skipped before private filtering
  //   => mock skipping precedence is preserved for selected private names.
  claim <k> keepPrivate(true, selNames(ListItem("_one")),
                        member("_one", true, true, false, false, true)) => false </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_existing_filter_contract: explicit members are documented even if private,
  //   subject to the same documentation rule
  //   => want_all false keeps a documented explicit private member.
  claim <k> keepPrivate(false, selNone,
                        member("_one", true, true, false, false, false)) => true </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_existing_attr_doc_behavior: source-documented attributes count as documented
  //   => selected private attributes with attr docs are kept in all-members mode.
  claim <k> keepPrivate(true, selNames(ListItem("_attr")),
                        member("_attr", true, false, true, false, false)) => true </k>
    [all-path]
endmodule

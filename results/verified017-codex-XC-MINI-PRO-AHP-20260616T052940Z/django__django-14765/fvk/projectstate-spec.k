requires "mini-python.k"

module PROJECTSTATE-SPEC
  imports MINI-PROJECTSTATE

  // SPEC-PROVENANCE:
  // - from_prompt: "assert that it's a set when non-None" => None is the
  //   allowed sentinel and creates an empty set.
  // - from_code: successful construction also assigns models, is_delayed, and
  //   relations as before.
  claim
    <k> initProjectState(none) => .K </k>
    <models> unset => modelsValue </models>
    <realAppsAttr> unset => emptySetValue </realAppsAttr>
    <isDelayed> unset => falseValue </isDelayed>
    <relations> unset => noneValue </relations>
    <result> unset => ok </result>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: "assert that it's a set when non-None" => an empty set is
  //   non-None and must pass the assertion rather than falling through a
  //   truthiness check.
  claim
    <k> initProjectState(emptySet) => .K </k>
    <models> unset => modelsValue </models>
    <realAppsAttr> unset => sameEmptySet </realAppsAttr>
    <isDelayed> unset => falseValue </isDelayed>
    <relations> unset => noneValue </relations>
    <result> unset => ok </result>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: "real_apps argument is a set" => a provided non-empty set is
  //   accepted directly.
  claim
    <k> initProjectState(nonEmptySet) => .K </k>
    <models> unset => modelsValue </models>
    <realAppsAttr> unset => sameNonEmptySet </realAppsAttr>
    <isDelayed> unset => falseValue </isDelayed>
    <relations> unset => noneValue </relations>
    <result> unset => ok </result>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: "instead of ... converting it to a set if not" => non-set
  //   non-None values assert and are not converted or assigned to real_apps.
  claim
    <k> initProjectState(nonSet) => .K </k>
    <models> unset => modelsValue </models>
    <realAppsAttr> unset => unset </realAppsAttr>
    <isDelayed> unset => unset </isDelayed>
    <relations> unset => unset </relations>
    <result> unset => assertionError </result>
    [all-path]
endmodule

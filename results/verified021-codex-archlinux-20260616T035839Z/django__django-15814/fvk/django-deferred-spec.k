requires "mini-python.k"

module DJANGO-DEFERRED-SPEC
  imports MINI-PYTHON
  imports BOOL

  // SPEC-PROVENANCE:
  // - from_prompt: QuerySet.only() after select_related() crashes on proxy
  //   models with ValueError "'id' is not in list".
  // - from_prompt: select_related("custom").only("custom__name") follows a
  //   ForeignKey to ProxyCustomModel and asks for the concrete field "name".
  // - from_code: get_default_columns() checks field.model in only_load, and
  //   RelatedPopulator requires the related pk attname in init_list.
  // Claim PROXY-ONLY-PK.
  claim
    <k> buildOnlyMask(anotherModel, proxyCustomModel, customFk, nameField)
        ~> defaultColumns(customModel)
        => .K ... </k>
    <mustInclude> .KeyedFields => ?MI:KeyedFields </mustInclude>
    <seen> .KeyedFields => ?SEEN:KeyedFields </seen>
    <loadMask> .KeyedFields => ?LM:KeyedFields </loadMask>
    <selected> .Fields => ?SEL:Fields </selected>
    ensures hasKeyField(?LM, customModel, idField)
        andBool hasKeyField(?LM, customModel, nameField)
        andBool hasField(?SEL, idField)
        andBool hasField(?SEL, nameField)
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: fix proxy behavior without changing non-proxy behavior.
  // - from_default_domain: concrete(T) is T for a non-proxy target.
  // Claim CONCRETE-TARGET-FRAME.
  claim
    <k> buildOnlyMask(anotherModel, customModel, customFk, nameField)
        ~> defaultColumns(customModel)
        => .K ... </k>
    <mustInclude> .KeyedFields => ?MI:KeyedFields </mustInclude>
    <seen> .KeyedFields => ?SEEN:KeyedFields </seen>
    <loadMask> .KeyedFields => ?LM:KeyedFields </loadMask>
    <selected> .Fields => ?SEL:Fields </selected>
    ensures hasKeyField(?LM, customModel, idField)
        andBool hasKeyField(?LM, customModel, nameField)
        andBool hasField(?SEL, idField)
        andBool hasField(?SEL, nameField)
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: the reported crash is caused by the pk attname "id" being
  //   absent from the related init list.
  // - from_code: without concrete-model normalization, the pk is recorded
  //   under the proxy key while defaultColumns(customModel) checks the concrete
  //   key. This is a counterexample claim, not desired production behavior.
  // Claim LEGACY-PROXY-COUNTEREXAMPLE.
  claim
    <k> legacyBuildOnlyMask(anotherModel, proxyCustomModel, customFk, nameField)
        ~> defaultColumns(customModel)
        => .K ... </k>
    <mustInclude> .KeyedFields => ?MI:KeyedFields </mustInclude>
    <seen> .KeyedFields => ?SEEN:KeyedFields </seen>
    <loadMask> .KeyedFields => ?LM:KeyedFields </loadMask>
    <selected> .Fields => ?SEL:Fields </selected>
    ensures notBool hasKeyField(?LM, customModel, idField)
        andBool hasKeyField(?LM, proxyCustomModel, idField)
        andBool notBool hasField(?SEL, idField)
        andBool hasField(?SEL, nameField)
    [all-path]
endmodule

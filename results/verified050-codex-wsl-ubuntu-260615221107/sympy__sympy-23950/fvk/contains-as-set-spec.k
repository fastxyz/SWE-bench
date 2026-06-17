// Spec for the mini SymPy as_set fragment.
// Status: constructed, not machine-checked.

requires "mini-sympy-as-set.k"

module CONTAINS-AS-SET-SPEC
  imports MINI-SYMPY-AS-SET

  // SPEC-PROVENANCE:
  // - from_prompt: "if x is a symbol, Contains(x, set).as_set() should just return set"
  // - from_code: Contains.as_set constructs ConditionSet(x, self)
  // - from_code: ConditionSet flattens Contains(x, set) to set intersect base_set
  claim [CONTAINS-AS-SET-SYMBOL]:
    <k> containsAsSet(Contains(x, Reals)) => Reals </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: "unless contains is False in which case EmptySet should be returned"
  // - from_code: EmptySet intersect UniversalSet is EmptySet
  claim [CONTAINS-AS-SET-EMPTY]:
    <k> containsAsSet(Contains(x, EmptySet)) => EmptySet </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: "superclass Boolean should define as_set to return a ConditionSet"
  // - from_code: Boolean._eval_as_set returns ConditionSet(free_symbol, self)
  claim [BOOLEAN-EVAL-AS-SET-ONE-FREE]:
    <k> booleanEvalAsSet(Boolean(x))
      => ConditionSet(x, Boolean(x), UniversalSet) </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_code: ConditionSet.__new__ membership flattening rule
  // - from_code: UniversalSet is intersection identity
  claim [CONDITIONSET-CONTAINS-FLATTEN]:
    <k> ConditionSet(x, Contains(x, ParamSet(y)), UniversalSet)
      => ParamSet(y) </k>
    [all-path]
endmodule

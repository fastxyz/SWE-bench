// Constructed, not machine-checked.
// K-style claims for the django__django-15128 alias-collision fix.

requires "mini-query-alias.k"

module QUERY-ALIAS-SPEC
  imports MINI-QUERY-ALIAS
  imports BOOL

  // SPEC-PROVENANCE:
  // - from_prompt: "Query.change_aliases raises an AssertionError" with
  //   "change_map = {'T4': 'T5', 'T5': 'T6'}" => keys(change_map) and
  //   values(change_map) must be disjoint before relabeling.
  // - from_prompt_hints: "adjust all the aliases but the initial one" =>
  //   firstAliasSet(RALIASES) is excluded from prefix relabeling.
  // - from_code: V1 calls rhs.bump_prefix(self, exclude={initial_alias})
  //   on a clone before Query.combine() builds its change_map.
  claim
    <k> bumpExcept(RP, RALIASES, firstAliasSet(RALIASES), USED)
      => bumped(?P:Prefix, ?RALIASES2:AliasList, ?CM:ChangeMap)
    </k>
    ensures
      disjoint(keys(?CM), values(?CM))
      andBool disjoint(values(?CM), firstAliasSet(RALIASES))
      andBool preserves(RALIASES, ?RALIASES2, firstAliasSet(RALIASES))
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt_hints: combine requires both queries to share the same
  //   initial alias, otherwise the alias merge starts from the wrong base.
  // - from_code: combine skips list(rhs.alias_map)[0], then relabels all
  //   remaining RHS aliases through the change map it constructs.
  claim
    <k> combineNormalize(LP, LALIASES, RP, RALIASES, USED)
      => normalized(?RALIASES2:AliasList, ?CM:ChangeMap)
    </k>
    requires LP ==String RP
    ensures
      sameInitialAlias(RALIASES, ?RALIASES2)
      andBool disjoint(keys(?CM), values(?CM))
      andBool noGeneratedKeyCollision(?CM, RALIASES)
    [all-path]
endmodule

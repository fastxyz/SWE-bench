// Constructed, not machine-checked.
// Mini alias-calculus semantics for the django__django-15128 FVK audit.
// This abstracts Django Query objects down to the alias facts relevant to
// Query.combine(), Query.bump_prefix(), and Query.change_aliases().

module MINI-QUERY-ALIAS-SYNTAX
  imports STRING-SYNTAX
  imports BOOL-SYNTAX

  syntax Alias ::= String
  syntax Prefix ::= String

  syntax AliasList ::= ".AliasList"
                     | Alias ";" AliasList [right]

  syntax AliasSet ::= ".AliasSet"
                    | AliasSet Alias [left]

  syntax ChangeMap ::= ".ChangeMap"
                     | ChangeMap "[" Alias "|->" Alias "]" [left]

  syntax Cmd ::= bumpExcept(Prefix, AliasList, AliasSet, AliasSet)
               | combineNormalize(Prefix, AliasList, Prefix, AliasList, AliasSet)

  syntax Result ::= bumped(Prefix, AliasList, ChangeMap)
                  | normalized(AliasList, ChangeMap)

  syntax KResult ::= Result | Bool
endmodule

module MINI-QUERY-ALIAS
  imports MINI-QUERY-ALIAS-SYNTAX
  imports BOOL

  configuration <k> $PGM:Cmd </k>

  // Abstract helper functions. Their intended definitions are constrained by
  // the claims in query-alias-spec.k and by the proof obligations in
  // PROOF_OBLIGATIONS.md.
  syntax Prefix ::= nextFreshPrefix(Prefix, AliasSet) [function]
  syntax ChangeMap ::= makePrefixMap(Prefix, AliasList, AliasSet) [function]
  syntax AliasList ::= applyChangeMap(AliasList, ChangeMap) [function]
  syntax AliasSet ::= keys(ChangeMap) [function]
  syntax AliasSet ::= values(ChangeMap) [function]
  syntax Bool ::= disjoint(AliasSet, AliasSet) [function]
  syntax Bool ::= preserves(AliasList, AliasList, AliasSet) [function]
  syntax Bool ::= sameInitialAlias(AliasList, AliasList) [function]
  syntax Bool ::= noGeneratedKeyCollision(ChangeMap, AliasList) [function]

  rule <k> bumpExcept(P, ALIASES, EXCLUDE, USED)
        => bumped(
             nextFreshPrefix(P, USED),
             applyChangeMap(ALIASES, makePrefixMap(nextFreshPrefix(P, USED), ALIASES, EXCLUDE)),
             makePrefixMap(nextFreshPrefix(P, USED), ALIASES, EXCLUDE)
           )
       </k>

  rule <k> combineNormalize(LP, LALIASES, RP, RALIASES, USED)
        => normalized(
             applyChangeMap(RALIASES, makePrefixMap(nextFreshPrefix(RP, USED), RALIASES, firstAliasSet(RALIASES))),
             makePrefixMap(nextFreshPrefix(RP, USED), RALIASES, firstAliasSet(RALIASES))
           )
       </k>
       requires LP ==String RP

  syntax AliasSet ::= firstAliasSet(AliasList) [function]
endmodule

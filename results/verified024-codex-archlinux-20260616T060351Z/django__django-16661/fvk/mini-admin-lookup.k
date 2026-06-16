// Lightweight abstract semantics for the lookup_allowed() path normalizer.
// Constructed for FVK documentation; not machine-checked in this environment.

module MINI-ADMIN-LOOKUP-SYNTAX
  imports BOOL-SYNTAX
  imports STRING-SYNTAX

  syntax LookupCase ::= "issueLookup"
                      | "issueGeneratedLookup"
                      | "directGeneratedLookup"
                      | "realFieldBeyondLookup"

  syntax FilterSet ::= "issueFilterSet"
                     | "directFilterSet"

  syntax Bool ::= lookupAllowed(LookupCase, FilterSet) [function]
endmodule

module MINI-ADMIN-LOOKUP
  imports MINI-ADMIN-LOOKUP-SYNTAX
  imports BOOL

  configuration <k> $PGM:Bool </k>

  // issueLookup:
  //   actual candidate restaurant__place__country intersects issueFilterSet.
  rule lookupAllowed(issueLookup, issueFilterSet) => true

  // issueGeneratedLookup:
  //   trailing target id is stripped to restaurant__place__country.
  rule lookupAllowed(issueGeneratedLookup, issueFilterSet) => true

  // directGeneratedLookup:
  //   collapsed relation_parts length is one: restaurant.
  rule lookupAllowed(directGeneratedLookup, directFilterSet) => true

  // realFieldBeyondLookup:
  //   name is a real non-target field beyond the configured filter path.
  rule lookupAllowed(realFieldBeyondLookup, issueFilterSet) => false
endmodule

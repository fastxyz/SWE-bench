// K-style claims for the lookup_allowed() abstraction.
// Constructed for FVK documentation; not machine-checked in this environment.

requires "mini-admin-lookup.k"

module LOOKUP-ALLOWED-SPEC
  imports MINI-ADMIN-LOOKUP

  // SPEC-PROVENANCE:
  // - from_prompt: configured restaurant__place__country must be accepted.
  // - from_docs: list_filter field paths may span relations.
  claim <k> lookupAllowed(issueLookup, issueFilterSet) => true </k>

  // SPEC-PROVENANCE:
  // - from_code: RelatedFieldListFilter appends field.target_field.name.
  // - from_docs: list_filter field path remains the configured path.
  claim <k> lookupAllowed(issueGeneratedLookup, issueFilterSet) => true </k>

  // SPEC-PROVENANCE:
  // - from_docs: local/direct relation lookups are allowed.
  // - from_code: collapsed relation_parts length remains one.
  claim <k> lookupAllowed(directGeneratedLookup, directFilterSet) => true </k>

  // SPEC-PROVENANCE:
  // - from_docs: lookup_allowed sanitizes query-string lookups.
  // - from_prompt: restaurant__country is not a valid substitute path.
  claim <k> lookupAllowed(realFieldBeyondLookup, issueFilterSet) => false </k>
endmodule

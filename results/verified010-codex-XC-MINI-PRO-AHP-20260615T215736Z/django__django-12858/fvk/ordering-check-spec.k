requires "mini-django-ordering.k"

module MINI-DJANGO-ORDERING-SPEC
  imports MINI-DJANGO-ORDERING

  // SPEC-PROVENANCE:
  // - from_prompt: reported 'supply__product__parent__isnull' false positive.
  // - obligation: final registered lookup after a resolved relation path is valid.
  // Claim: REPORTED-CASE
  claim
    <k> validate(
          field(F_SUPPLY) ;
          field(F_PRODUCT) ;
          field(F_PARENT) ;
          missing(isnull) ;
          .Outcomes
        ) => ok ... </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: ordering uses lookups that are not transforms.
  // - obligation: final registered lookup is valid even when not a transform.
  // Claim: FINAL-LOOKUP-VALID
  claim
    <k> #walk(missing(isnull) ; .Outcomes, some(F_PARENT)) => ok ... </k>
    requires notBool hasTransform(F_PARENT, isnull) andBool hasLookup(F_PARENT, isnull)
    [all-path]

  // SPEC-PROVENANCE:
  // - from_existing_behavior: registered transforms were already accepted.
  // - obligation: preserve transform acceptance.
  // Claim: TRANSFORM-STILL-VALID
  claim
    <k> #walk(missing(lower) ; .Outcomes, some(F_TEXT)) => ok ... </k>
    requires hasTransform(F_TEXT, lower)
    [all-path]

  // SPEC-PROVENANCE:
  // - from_existing_behavior: invalid missing related fields still raise E015.
  // - obligation: a lookup-only unresolved segment is valid only when final.
  // Claim: NONFINAL-LOOKUP-INVALID
  claim
    <k> #walk(missing(isnull) ; missing(bogus) ; .Outcomes, some(F_PARENT)) => err ... </k>
    requires notBool hasTransform(F_PARENT, isnull) andBool hasLookup(F_PARENT, isnull)
    [all-path]
endmodule

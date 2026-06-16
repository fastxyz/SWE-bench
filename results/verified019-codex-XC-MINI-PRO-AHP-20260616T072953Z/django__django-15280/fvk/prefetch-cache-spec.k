requires "mini-prefetch-cache.k"

module PREFETCH-CACHE-SPEC-SYNTAX
  imports MINI-PREFETCH-CACHE-SYNTAX

  syntax Obj ::= "outerUser"
               | "innerUserWithKind"
               | "profile"
  syntax RelKey ::= "user"
                  | "profile"
endmodule

module PREFETCH-CACHE-VERIFICATION
  imports PREFETCH-CACHE-SPEC-SYNTAX
  imports MINI-PREFETCH-CACHE
  imports MAP-SYMBOLIC
  imports K-EQUAL

  rule { M:Map [ K <- V ] #Equals M:Map [ K <- V' ] } => { V #Equals V' }
    [simplification]
endmodule

module PREFETCH-CACHE-SPEC
  imports PREFETCH-CACHE-VERIFICATION

  // SPEC-PROVENANCE:
  // - from_problem: "kind on the inner User queryset had been deferred, which it hasn't"
  //   => an existing nested relation cache must not be overwritten by the outer origin.
  // - from_hint: "default to using the origin's object but allow overrides with nested prefetches"
  //   => cached nested relation wins over origin assignment.
  claim
    <k> seedIfMissing(profile, user, outerUser); => .K ... </k>
    <cache>
      cacheKey(profile, user) |-> innerUserWithKind
      => cacheKey(profile, user) |-> innerUserWithKind
    </cache>
    [label(preserveCachedRelation), all-path]

  // SPEC-PROVENANCE:
  // - from_hint: "default to using the origin's object"
  //   => missing relation caches are still populated with the origin object.
  claim
    <k> seedIfMissing(profile, user, outerUser); => .K ... </k>
    <cache>
      .Map
      => cacheKey(profile, user) |-> outerUser
    </cache>
    [label(seedMissingRelation), all-path]

  // SPEC-PROVENANCE:
  // - from_problem: one-to-one example plus "also happens if the relationship ... is a ForeignKey"
  //   => both descriptor paths use the same preserve/seed cache rule.
  claim
    <k>
      seedIfMissing(profile, user, outerUser);
      => .K
      ...
    </k>
    <cache>
      cacheKey(profile, user) |-> innerUserWithKind
      => cacheKey(profile, user) |-> innerUserWithKind
    </cache>
    [label(coverRelationFamily), all-path]
endmodule

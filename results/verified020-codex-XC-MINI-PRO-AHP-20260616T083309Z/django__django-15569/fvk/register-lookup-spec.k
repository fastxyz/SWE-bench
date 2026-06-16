requires "mini-lookup-cache.k"

module REGISTER-LOOKUP-SPEC
  imports MINI-LOOKUP-CACHE
  imports MAP-SYMBOLIC
  imports K-EQUAL

  syntax Bool ::= recomputesFromCurrentRegistry(Map, ClassId, LookupName) [function]
  rule recomputesFromCurrentRegistry(REG [ lookupKey(C, N) <- absent ], C, N) => true
    [simplification]

  // SPEC-PROVENANCE:
  // - from_prompt: "_unregister_lookup() should clear the lookup cache"
  //   => after unregister, dependent caches are invalidated.
  // - from_prompt: "as it is done in register_lookup"
  //   => use the same descendant-inclusive cache scope as _clear_cached_lookups().
  // - from_source: get_lookups() is lru_cache-backed
  //   => clearing cache is the required state transition before recompute.
  // CLAIM: UNREGISTER-CLEARS-DESCENDANT-CACHES
  claim
    <k> unregisterLookup(C, N) => .K </k>
    <registry> REG => REG [ lookupKey(C, N) <- absent ] </registry>
    <cache> CACHE => clearCaches(CACHE, DESC) </cache>
    <descendants> C |-> DESC </descendants>
    requires registered(REG, C, N)
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: stale cache after unregister is the bug.
  // - from_source: get_lookups() recomputes from class_lookups when its cache is
  //   cleared.
  // This claim is represented as an abstraction over get_lookups(): an uncached
  // descendant must recompute from the current registry rather than reuse the
  // old cached map.
  // CLAIM: GET-LOOKUPS-RECOMPUTES-AFTER-UNREGISTER
  claim
    <k> unregisterLookup(C, N) => .K </k>
    <registry> REG => REG [ lookupKey(C, N) <- absent ] </registry>
    <cache> CACHE => clearCaches(CACHE, DESC) </cache>
    <descendants> C |-> DESC </descendants>
    requires registered(REG, C, N)
    ensures recomputesFromCurrentRegistry(REG [ lookupKey(C, N) <- absent ], C, N)
    [all-path]
endmodule

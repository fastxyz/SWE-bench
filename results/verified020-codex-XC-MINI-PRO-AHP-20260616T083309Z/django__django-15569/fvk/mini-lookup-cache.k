module MINI-LOOKUP-CACHE-SYNTAX
  imports STRING-SYNTAX
  imports BOOL-SYNTAX
  imports MAP-SYNTAX
  imports SET-SYNTAX

  syntax ClassId ::= String
  syntax LookupName ::= String
  syntax LookupKey ::= "lookupKey" "(" ClassId "," LookupName ")"
  syntax CacheKey ::= "cacheKey" "(" ClassId ")"
  syntax LookupValue ::= "present" "(" String ")" | "absent"
  syntax CacheValue ::= "cached" "(" Map ")" | "uncached"
  syntax Cmd ::= "unregisterLookup" "(" ClassId "," LookupName ")"
  syntax Bool ::= registered(Map, ClassId, LookupName) [function]
endmodule

module MINI-LOOKUP-CACHE
  imports MINI-LOOKUP-CACHE-SYNTAX
  imports BOOL
  imports MAP
  imports SET

  configuration
    <k> $PGM:Cmd </k>
    <registry> .Map </registry>
    <cache> .Map </cache>
    <descendants> .Map </descendants>

  syntax Map ::= clearCaches(Map, Set) [function]
  rule clearCaches(CACHE, .Set) => CACHE
  rule clearCaches(CACHE, SetItem(C) REST)
    => clearCaches(CACHE [ cacheKey(C) <- uncached ], REST)

  // V1 source model:
  //   del cls.class_lookups[lookup_name]
  //   cls._clear_cached_lookups()
  rule
    <k> unregisterLookup(C, N) => .K </k>
    <registry> REG => REG [ lookupKey(C, N) <- absent ] </registry>
    <cache> CACHE => clearCaches(CACHE, DESC) </cache>
    <descendants> ... C |-> DESC ... </descendants>
    requires registered(REG, C, N)
endmodule

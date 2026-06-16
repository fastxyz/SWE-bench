module MINI-PREFETCH-CACHE-SYNTAX
  imports ID-SYNTAX
  imports MAP-SYNTAX

  syntax Obj ::= Id
  syntax RelKey ::= Id
  syntax CacheKey ::= "cacheKey" "(" Obj "," RelKey ")" [function]
  syntax Stmt ::= "seedIfMissing" "(" Obj "," RelKey "," Obj ")" ";"
  syntax KResult ::= Obj
endmodule

module MINI-PREFETCH-CACHE
  imports MINI-PREFETCH-CACHE-SYNTAX
  imports BOOL
  imports MAP

  configuration
    <k> $PGM:Stmt </k>
    <cache> .Map </cache>

  syntax Bool ::= hasCache(Map, Obj, RelKey) [function]
  rule hasCache(CACHE:Map, REL:Obj, KEY:RelKey)
    => cacheKey(REL, KEY) in_keys(CACHE)

  rule
    <k> seedIfMissing(REL:Obj, KEY:RelKey, ORIGIN:Obj); => .K ... </k>
    <cache> CACHE:Map => CACHE </cache>
    requires hasCache(CACHE, REL, KEY)

  rule
    <k> seedIfMissing(REL:Obj, KEY:RelKey, ORIGIN:Obj); => .K ... </k>
    <cache> CACHE:Map => CACHE [ cacheKey(REL, KEY) <- ORIGIN ] </cache>
    requires notBool hasCache(CACHE, REL, KEY)
endmodule


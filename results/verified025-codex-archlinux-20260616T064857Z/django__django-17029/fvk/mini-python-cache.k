// Constructed mini semantics for django__django-17029.
// This is not a full Python semantics. It models only the cache-state
// transitions relevant to Apps.clear_cache() and get_swappable_settings_name().

module MINI-PYTHON-CACHE-SYNTAX
  imports INT-SYNTAX
  imports BOOL-SYNTAX

  syntax Stmt ::= "clear_cache"
                | "clear_get_models_cache"
                | "clear_swappable_settings_name_cache"
                | "expire_model_meta_if_ready"
                | "get_swappable_settings_name"
                | "mutate_registry"
                | Stmt ";" Stmt [left]

  syntax KResult ::= Int | Bool
endmodule

module MINI-PYTHON-CACHE
  imports MINI-PYTHON-CACHE-SYNTAX
  imports INT
  imports BOOL

  configuration
    <k> $PGM:Stmt </k>
    <registryVersion> 0 </registryVersion>
    <modelsCacheVersion> -1 </modelsCacheVersion>
    <swappableCacheVersion> -1 </swappableCacheVersion>
    <lookupObservedVersion> -1 </lookupObservedVersion>
    <ready> false </ready>
    <metaCachesExpired> false </metaCachesExpired>

  rule <k> S1:Stmt ; S2:Stmt => S1 ~> S2 ... </k>

  // V1 maps Apps.clear_cache() to these three observable effects:
  // self.get_models.cache_clear();
  // self.get_swappable_settings_name.cache_clear();
  // if self.ready: expire each model _meta cache.
  rule <k> clear_cache
        => clear_get_models_cache ;
           clear_swappable_settings_name_cache ;
           expire_model_meta_if_ready
        ... </k>

  rule <k> clear_get_models_cache => .K ... </k>
       <modelsCacheVersion> _ => -1 </modelsCacheVersion>

  rule <k> clear_swappable_settings_name_cache => .K ... </k>
       <swappableCacheVersion> _ => -1 </swappableCacheVersion>

  rule <k> expire_model_meta_if_ready => .K ... </k>
       <ready> true </ready>
       <metaCachesExpired> _ => true </metaCachesExpired>

  rule <k> expire_model_meta_if_ready => .K ... </k>
       <ready> false </ready>

  // Abstract registry mutation used by the proof obligation for callers that
  // mutate the app registry and then rely on clear_cache().
  rule <k> mutate_registry => .K ... </k>
       <registryVersion> RV:Int => RV +Int 1 </registryVersion>

  // A swappable lookup uses its cache when populated. If the cache is empty,
  // it computes from the current registry and populates the cache with that
  // current registry version.
  rule <k> get_swappable_settings_name => .K ... </k>
       <registryVersion> RV:Int </registryVersion>
       <swappableCacheVersion> -1 => RV </swappableCacheVersion>
       <lookupObservedVersion> _ => RV </lookupObservedVersion>

  rule <k> get_swappable_settings_name => .K ... </k>
       <swappableCacheVersion> CV:Int </swappableCacheVersion>
       <lookupObservedVersion> _ => CV </lookupObservedVersion>
    requires CV =/=Int -1
endmodule

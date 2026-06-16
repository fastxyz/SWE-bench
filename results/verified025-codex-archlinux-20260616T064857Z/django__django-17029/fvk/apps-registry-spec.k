requires "mini-python-cache.k"

module APPS-REGISTRY-SPEC
  imports MINI-PYTHON-CACHE
  imports INT
  imports BOOL

  // SPEC-PROVENANCE:
  // - from_prompt: "clear_cache doc states: Clear all internal caches" =>
  //   both app-registry cache cells must be empty after clear_cache().
  // - from_code: registry.py has @functools.cache on get_models() and
  //   get_swappable_settings_name(); clear_cache() expires model _meta caches
  //   only under if self.ready.
  // - conflicts: pre-fix code did not clear the swappable cache.
  // CLAIM: CLEAR-CACHE-READY
  claim
    <k> clear_cache => .K </k>
    <registryVersion> RV:Int => RV </registryVersion>
    <modelsCacheVersion> MC:Int => -1 </modelsCacheVersion>
    <swappableCacheVersion> SC:Int => -1 </swappableCacheVersion>
    <lookupObservedVersion> LO:Int => LO </lookupObservedVersion>
    <ready> true </ready>
    <metaCachesExpired> ME:Bool => true </metaCachesExpired>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: same all-internal-caches obligation as above.
  // - from_code: when ready is false, clear_cache() skips model _meta expiry;
  //   this branch must remain unchanged by the fix.
  // CLAIM: CLEAR-CACHE-NOT-READY
  claim
    <k> clear_cache => .K </k>
    <registryVersion> RV:Int => RV </registryVersion>
    <modelsCacheVersion> MC:Int => -1 </modelsCacheVersion>
    <swappableCacheVersion> SC:Int => -1 </swappableCacheVersion>
    <lookupObservedVersion> LO:Int => LO </lookupObservedVersion>
    <ready> false </ready>
    <metaCachesExpired> ME:Bool => ME </metaCachesExpired>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: django-stubs uses clear_cache() to reset previous state;
  //   stale get_swappable_settings_name() values must not survive that reset.
  // - from_code: get_swappable_settings_name() result is cached and depends on
  //   get_models(include_swapped=True).
  // CLAIM: LOOKUP-AFTER-CLEAR-READY
  claim
    <k> clear_cache ; get_swappable_settings_name => .K </k>
    <registryVersion> RV:Int => RV </registryVersion>
    <modelsCacheVersion> MC:Int => -1 </modelsCacheVersion>
    <swappableCacheVersion> SC:Int => RV </swappableCacheVersion>
    <lookupObservedVersion> LO:Int => RV </lookupObservedVersion>
    <ready> true </ready>
    <metaCachesExpired> ME:Bool => true </metaCachesExpired>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: the swappable cache reset must not depend on ready-state.
  // - from_code: cache_clear() calls are outside the if self.ready block.
  // CLAIM: LOOKUP-AFTER-CLEAR-NOT-READY
  claim
    <k> clear_cache ; get_swappable_settings_name => .K </k>
    <registryVersion> RV:Int => RV </registryVersion>
    <modelsCacheVersion> MC:Int => -1 </modelsCacheVersion>
    <swappableCacheVersion> SC:Int => RV </swappableCacheVersion>
    <lookupObservedVersion> LO:Int => RV </lookupObservedVersion>
    <ready> false </ready>
    <metaCachesExpired> ME:Bool => ME </metaCachesExpired>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_code: register_model(), set_available_apps(), set_installed_apps(),
  //   unset_* methods, and migration StateApps paths centralize invalidation
  //   by calling clear_cache().
  // - from_prompt: clear_cache() must reset old state across consequential runs.
  // CLAIM: MUTATE-CLEAR-LOOKUP-READY
  claim
    <k> mutate_registry ; clear_cache ; get_swappable_settings_name => .K </k>
    <registryVersion> RV:Int => RV +Int 1 </registryVersion>
    <modelsCacheVersion> MC:Int => -1 </modelsCacheVersion>
    <swappableCacheVersion> SC:Int => RV +Int 1 </swappableCacheVersion>
    <lookupObservedVersion> LO:Int => RV +Int 1 </lookupObservedVersion>
    <ready> true </ready>
    <metaCachesExpired> ME:Bool => true </metaCachesExpired>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_code: same centralized invalidation paths as the ready claim.
  // - from_prompt: clear_cache() must reset old state across consequential runs.
  // - from_code: when ready is false, model _meta expiry remains skipped while
  //   both app-registry caches are still cleared.
  // CLAIM: MUTATE-CLEAR-LOOKUP-NOT-READY
  claim
    <k> mutate_registry ; clear_cache ; get_swappable_settings_name => .K </k>
    <registryVersion> RV:Int => RV +Int 1 </registryVersion>
    <modelsCacheVersion> MC:Int => -1 </modelsCacheVersion>
    <swappableCacheVersion> SC:Int => RV +Int 1 </swappableCacheVersion>
    <lookupObservedVersion> LO:Int => RV +Int 1 </lookupObservedVersion>
    <ready> false </ready>
    <metaCachesExpired> ME:Bool => ME </metaCachesExpired>
    [all-path]
endmodule

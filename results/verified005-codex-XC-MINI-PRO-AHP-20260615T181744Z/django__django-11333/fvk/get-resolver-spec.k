// Constructed, not machine-checked.
// SPEC-PROVENANCE is summarized in fvk/SPEC.md and mirrored here.

requires "mini-resolver-cache.k"

module GET-RESOLVER-SPEC
  imports MINI-RESOLVER-CACHE

  // SPEC-PROVENANCE:
  // - from_prompt: calls before set_urlconf use None, calls after request
  //   handling use settings.ROOT_URLCONF; these must not construct separate
  //   URLResolver instances for the same default root URLconf.
  // - from_docs: ROOT_URLCONF is the default root URLconf, and request.urlconf
  //   may be None to return to that default.
  // - from_code: get_resolver normalizes None before delegating to the cached
  //   helper, whose key is the normalized URLconf.
  claim
    <k> getResolver(OmittedUrlConf) ~> getResolver(NoUrlConf) ~> getResolver(url(R:Id)) => .K </k>
    <root> R </root>
    <cache> .Map => R |-> 1 </cache>
    <next> 1 => 2 </next>
    <result> 0 => 1 </result>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: only equivalent default forms should collapse; explicit
  //   non-default URLconfs remain independently cached.
  // - from_code: _get_cached_resolver receives the explicit non-None URLconf.
  claim
    <k> getResolver(url(U:Id)) ~> getResolver(url(V:Id)) => .K </k>
    <root> R:Id </root>
    <cache> .Map => U |-> 1 V |-> 2 </cache>
    <next> 1 => 3 </next>
    <result> 0 => 2 </result>
    requires U =/=K R andBool V =/=K R andBool U =/=K V
    [all-path]

  // SPEC-PROVENANCE:
  // - from_code: clear_url_caches() calls get_resolver.cache_clear().
  // - compatibility obligation: forwarding cache_clear must clear the helper
  //   cache that stores normalized URLconf entries.
  claim
    <k> getResolver(NoUrlConf) ~> clearResolverCache ~> getResolver(NoUrlConf) => .K </k>
    <root> R:Id </root>
    <cache> .Map => R |-> 2 </cache>
    <next> 1 => 3 </next>
    <result> 0 => 2 </result>
    [all-path]
endmodule

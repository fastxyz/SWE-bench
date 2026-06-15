# FVK Spec: get_resolver Cache Normalization

Constructed, not machine-checked.

## Scope

The audited unit is `django.urls.resolvers.get_resolver()` as changed in V1,
plus the cache-control compatibility required by `django.urls.base.clear_url_caches()`.
The property under verification is resolver-cache identity for equivalent
default URLconf inputs, not URL pattern resolution itself or
`URLResolver._populate()` internals.

## Intent Spec

1. When no per-thread URLconf has been set, callers may pass `None` or omit the
   argument, and this means the default `settings.ROOT_URLCONF`.
2. A later call that passes `settings.ROOT_URLCONF` explicitly must reuse the
   same cached resolver that an earlier default-form call created.
3. Explicit non-`None` URLconfs that are not the default remain distinct cache
   keys.
4. Cache clearing through `clear_url_caches()` must clear the resolver cache
   actually used by `get_resolver()`.
5. Existing `set_urlconf()` and `get_urlconf()` semantics are frame conditions:
   `get_urlconf()` reports a thread-local override and may return `None`.

## Public Evidence Ledger

| ID | Source | Evidence | Semantic obligation | Status |
| --- | --- | --- | --- | --- |
| E1 | `benchmark/PROBLEM.md` | "`get_resolver` constructs a new URLResolver, and caches it using functools.lru_cache." | The observable bug is duplicate construction/cache entries. | Encoded in PO-1 and claim 1. |
| E2 | `benchmark/PROBLEM.md` | "Initially it will be called with None, and later ... with settings.ROOT_URLCONF" | `None` and the configured root are equivalent default inputs. | Encoded in PO-1 and claim 1. |
| E3 | `benchmark/PROBLEM.md` | "modify `get_resolver` to look up settings.ROOT_URLCONF before the memoized function call" | Normalization must occur before the LRU cache key is formed. | Encoded in PO-1. |
| E4 | `repo/docs/ref/settings.txt` | "`ROOT_URLCONF` ... A string representing the full Python import path to your root URLconf" | The default root URLconf is the documented default URLconf value and is hashable in the documented domain. | Domain assumption in PO-6. |
| E5 | `repo/docs/ref/request-response.txt` | "`urlconf` can be set to `None` ... return to using the `ROOT_URLCONF`" | `None` means fallback to default root URLconf. | Encoded in PO-1 and claim 1. |
| E6 | `repo/django/urls/base.py` | `clear_url_caches()` calls `get_resolver.cache_clear()` | Public/internal cache clearing must still clear resolver entries. | Encoded in PO-4 and claim 3. |
| E7 | `repo/django/urls/base.py` | `get_urlconf(default=None)` returns the thread-local value or `default` | `get_urlconf()` must not be changed to always return `settings.ROOT_URLCONF`. | Frame condition in PO-5. |

## Formal Model

The K model is in `fvk/mini-resolver-cache.k`; claims are in
`fvk/get-resolver-spec.k`.

The model abstracts a resolver object to a fresh integer construction id. It
keeps cells for:

- `<root>`: the configured default URLconf.
- `<cache>`: normalized URLconf key to resolver construction id.
- `<next>`: the next construction id.
- `<result>`: the id returned by the most recent call.

The abstraction distinguishes the property under test: a failing implementation
that keys `None`, omitted, and explicit root separately reaches `<next> 4`,
while the intended implementation reaches `<next> 2` after the three default
forms.

## Formal Spec English

Claim 1: Starting with an empty cache, `getResolver(OmittedUrlConf)`,
`getResolver(NoUrlConf)`, and `getResolver(url(ROOT))` produce one construction
id and leave a single cache entry keyed by `ROOT`.

Claim 2: Starting with an empty cache, two distinct explicit non-default
URLconfs produce two distinct construction ids and two cache entries.

Claim 3: A default resolver constructed before `clearResolverCache` is not reused
after clearing; the post-clear default call constructs a new id.

## Spec Audit

Claim 1 passes. It directly encodes E1, E2, E3, and E5.

Claim 2 passes. The issue only requires collapsing equivalent default forms; no
public evidence supports collapsing arbitrary explicit URLconfs.

Claim 3 passes. It is required by E6 because `clear_url_caches()` is the public
internal hook that resets URL resolver caches after setting changes.

The domain assumption that `ROOT_URLCONF` is hashable passes for the documented
setting form in E4 and for public in-repo tests that use strings or classes.
Explicit unhashable URLconf objects are outside this proof's domain.

## Public Compatibility Audit

Changed symbol: `django.urls.resolvers.get_resolver`.

Public signature compatibility: preserved as `get_resolver(urlconf=None)`.

Return shape compatibility: preserved; returns a `URLResolver` constructed with
`RegexPattern(r'^/')` and the effective URLconf.

Cache-control compatibility: preserved for observed public/internal use because
`get_resolver.cache_clear` and `get_resolver.cache_info` forward to the cached
helper. `clear_url_caches()` still calls `get_resolver.cache_clear()`.

Callsite compatibility: existing callsites in `django.urls.base`,
`django.core.handlers`, URL checks, i18n helpers, admindocs, and autoreload
continue to pass either no argument, `None`, `settings.ROOT_URLCONF`, or an
explicit non-default URLconf. The normalized helper preserves those cases.

No public subclass or virtual-dispatch compatibility issue applies; this is a
module-level function.

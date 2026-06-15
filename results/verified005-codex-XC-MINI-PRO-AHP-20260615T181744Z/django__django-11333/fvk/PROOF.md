# FVK Proof

Constructed, not machine-checked.

## Claims Proved in the Model

The formal artifacts are:

- `fvk/mini-resolver-cache.k`
- `fvk/get-resolver-spec.k`

Exact commands to machine-check later, not executed in this session:

```sh
kompile fvk/mini-resolver-cache.k --backend haskell
kast --backend haskell fvk/get-resolver-spec.k
kprove fvk/get-resolver-spec.k
```

Expected machine-check result if the constructed proof is accepted: `#Top`.

## Proof Sketch

The mini semantics models a resolver construction as a fresh integer id stored
in `<cache>` under a normalized URLconf key. `norm(NoUrlConf, R) = R`,
`norm(OmittedUrlConf, R) = R`, and `norm(url(U), R) = U` for explicit `U`.

For claim 1, start with an empty cache and root `R`. The first
`getResolver(OmittedUrlConf)` call misses under key `R`, stores `R |-> 1`, advances
`<next>` from `1` to `2`, and returns id `1`. The subsequent
`getResolver(NoUrlConf)` and `getResolver(url(R))` calls both normalize to `R`,
hit the existing cache entry, leave `<next>` at `2`, and return id `1`. Thus
the three default forms cause exactly one construction.

For claim 2, explicit non-default `U` and `V` normalize to themselves. Starting
from an empty cache, the first call stores `U |-> 1`; the second call stores
`V |-> 2`. The side condition `U =/=K R andBool V =/=K R andBool U =/=K V`
prevents accidental collapse with the default root or each other.

For claim 3, `getResolver(NoUrlConf)` first stores `R |-> 1`. The
`clearResolverCache` rule rewrites the cache to `.Map`. The final
`getResolver(NoUrlConf)` misses again under key `R`, stores `R |-> 2`, and
returns a new construction id. This models `clear_url_caches()` clearing the
active helper cache through `get_resolver.cache_clear`.

## Correspondence to Python V1

`repo/django/urls/resolvers.py` implements the model's `norm` step in the public
function:

```python
def get_resolver(urlconf=None):
    if urlconf is None:
        urlconf = settings.ROOT_URLCONF
    return _get_cached_resolver(urlconf)
```

The memoized transition is the private helper:

```python
@functools.lru_cache(maxsize=None)
def _get_cached_resolver(urlconf=None):
    return URLResolver(RegexPattern(r'^/'), urlconf)
```

The cache-clear claim corresponds to:

```python
get_resolver.cache_clear = _get_cached_resolver.cache_clear
```

and to `clear_url_caches()` calling `get_resolver.cache_clear()`.

## Adequacy

The proof directly covers the issue's reported sequence: a default-form resolver
call before request handling sets the thread-local URLconf, followed by a call
with `settings.ROOT_URLCONF` after request handling. It also covers the frame
case that explicit non-default URLconfs stay distinct.

The model deliberately abstracts away `URLResolver._populate()` contents. That
is adequate because the issue is about duplicate resolver instances and their
duplicated instance caches, not about the correctness of route matching.

## Residual Risk

This proof is constructed but not machine-checked. The emitted K commands were
not run, and no Python or Django tests were run.

The proof is partial over the stated domain. It assumes a configured,
hashable effective URLconf, matching the documented `ROOT_URLCONF` string
setting and the hashable URLconf objects used in public tests.

No test deletion is recommended. A future machine-checked proof could make a
narrow unit test for default-form cache identity redundant, but integration,
settings-change, request-middleware, and URL resolution tests should remain.

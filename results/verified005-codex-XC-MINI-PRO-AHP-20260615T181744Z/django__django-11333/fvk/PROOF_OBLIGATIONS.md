# FVK Proof Obligations

Constructed, not machine-checked.

## PO-1: Normalize default-form URLconf before cache lookup

Statement: For every call to `get_resolver(urlconf)`, if `urlconf is None` or
the argument is omitted, the cache key used by the memoized resolver factory is
`settings.ROOT_URLCONF`.

Evidence: E2, E3, E5.

V1 status: discharged. The public `get_resolver()` performs the `None` check and
then calls `_get_cached_resolver(urlconf)`.

## PO-2: Equivalent default forms share one construction

Statement: With fixed `settings.ROOT_URLCONF = R`, calls
`get_resolver()`, `get_resolver(None)`, and `get_resolver(R)` must use the same
cached resolver entry until caches are cleared.

Evidence: E1, E2, E3.

V1 status: discharged by PO-1 and by the helper cache being keyed only by the
normalized URLconf.

## PO-3: Explicit non-default URLconfs are preserved

Statement: For `urlconf = U` where `U is not None` and `U != settings.ROOT_URLCONF`,
`get_resolver(U)` must use `U` as the cache key and construct a resolver for `U`.

Evidence: Existing callsites pass request-specific URLconfs; the issue only
targets duplicate default forms.

V1 status: discharged. The public function only rewrites `None`; non-`None`
values pass through unchanged.

## PO-4: Cache clearing reaches the active resolver cache

Statement: `clear_url_caches()` must clear the cache that stores
`_get_cached_resolver` entries.

Evidence: E6.

V1 status: discharged. `get_resolver.cache_clear` is assigned from
`_get_cached_resolver.cache_clear`.

## PO-5: Thread-local URLconf semantics are unchanged

Statement: `get_urlconf(default=None)` must continue to return the thread-local
override if present, otherwise `default`; `set_urlconf(None)` must continue to
clear the override.

Evidence: E7 and public tests that assert `get_urlconf()` is `None` after a
request.

V1 status: discharged by non-interference. V1 does not edit `django/urls/base.py`
or any `set_urlconf()`/`get_urlconf()` logic.

## PO-6: Domain and error behavior are explicit

Statement: The proof domain is a configured Django settings object whose
`ROOT_URLCONF` is the documented string import path or another hashable URLconf
object. Missing `ROOT_URLCONF` and explicit unhashable URLconf inputs are not
proved by this model.

Evidence: E4; existing LRU-cache behavior already required hashability for
explicit non-`None` arguments.

V1 status: accepted boundary. No code change is justified by the issue.

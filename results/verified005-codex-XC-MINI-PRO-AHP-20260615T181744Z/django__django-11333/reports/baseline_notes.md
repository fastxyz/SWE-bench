# Baseline Notes

## Root cause

`django.urls.resolvers.get_resolver()` was decorated directly with
`functools.lru_cache()`. Its function body converted a `None` URLconf to
`settings.ROOT_URLCONF`, but `lru_cache()` builds the cache key before the
function body runs. As a result, calls such as `get_resolver()`,
`get_resolver(None)`, and `get_resolver(settings.ROOT_URLCONF)` could create
separate cached `URLResolver` instances for the same effective root URLconf.

Those duplicate resolver instances each own their own populated reverse and
namespace caches, so applications with large URLconfs could pay the cost of
`URLResolver._populate()` more than once for the same default resolver.

## Files changed

`repo/django/urls/resolvers.py`

Moved the LRU cache from the public `get_resolver()` entry point to a private
`_get_cached_resolver()` helper. The public function now resolves `None` to
`settings.ROOT_URLCONF` before entering the cached helper, so all default-root
forms share the same cache key. The helper still constructs the same
`URLResolver(RegexPattern(r'^/'), urlconf)` object as before.

The helper's `cache_clear` and `cache_info` methods are assigned back to
`get_resolver` so existing internal callers such as `clear_url_caches()` keep
working without changes.

`reports/baseline_notes.md`

Added this required benchmark report documenting the root cause, source change,
assumptions, and rejected alternatives.

## Assumptions and rejected alternatives

I assumed the intended semantic equivalence is limited to an omitted or `None`
URLconf meaning the configured `settings.ROOT_URLCONF`; explicit non-`None`
URLconfs should continue to be cached independently.

I considered changing `get_urlconf()` so it returns `settings.ROOT_URLCONF` by
default. I rejected that because `get_urlconf()` currently reports only a
thread-local override, and existing tests and callers may depend on receiving
`None` when no override has been set.

I considered changing each caller, such as `reverse()` or request handling, to
avoid passing `None`. I rejected that because it would be less complete and
would not protect third-party code that calls `get_resolver(None)` directly.

I did not run tests or project code because the task explicitly forbids code
execution in this benchmark environment.

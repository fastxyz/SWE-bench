# Baseline Notes

## Root cause

`django.apps.registry.Apps.clear_cache()` only cleared the cached result of
`Apps.get_models()`. The same class also caches
`Apps.get_swappable_settings_name()`, whose result depends on the current model
registry via `get_models(include_swapped=True)`. When the app registry is
altered by methods such as `register_model()`, `set_available_apps()`, or
`set_installed_apps()`, `clear_cache()` can leave stale swappable model setting
lookups behind.

## Files changed

`repo/django/apps/registry.py`

Added `self.get_swappable_settings_name.cache_clear()` to
`Apps.clear_cache()` alongside the existing `self.get_models.cache_clear()`.
This keeps the method's documented contract of clearing internal app-registry
caches and invalidates swappable setting lookups whenever registry-changing
methods call `clear_cache()`.

## Assumptions and alternatives

Assumed the intended behavior is for `clear_cache()` to clear all caches owned
by the app registry class, including cached methods that indirectly depend on
the model list.

Considered removing the cache from `get_swappable_settings_name()`, but rejected
that because its docstring says the cache is deliberate for migration
performance.

Considered clearing the swappable-settings cache only in specific mutation
methods, but rejected that because those methods already centralize app-registry
cache invalidation through `clear_cache()`.

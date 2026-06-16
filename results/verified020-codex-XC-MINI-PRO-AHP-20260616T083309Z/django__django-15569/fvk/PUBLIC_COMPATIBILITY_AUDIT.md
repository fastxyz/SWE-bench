# PUBLIC_COMPATIBILITY_AUDIT

Changed symbol: `RegisterLookupMixin._unregister_lookup(cls, lookup, lookup_name=None)`.

## Signature and Return Shape

V1 keeps the same signature and does not add a return value. Compatibility:
pass.

## Callers

| Caller | Usage | Compatibility result |
| --- | --- | --- |
| `django.test.utils.register_lookup()` | Calls `_unregister_lookup(lookup, lookup_name)` in a context manager `finally` block. | Pass. The call still succeeds and now clears dependent caches. |
| `django.contrib.postgres.apps.uninstall_if_needed()` | Calls `_unregister_lookup()` for lookups registered in `PostgresConfig.ready()`. | Pass. Successful unregister still removes the lookup and now avoids stale lookup caches after app removal. |
| Public tests under `repo/tests/custom_lookups/` | Direct unregister during setup/teardown or cleanup. | Pass. Signature and exception behavior unchanged. |
| `repo/tests/model_fields/test_jsonfield.py` | Calls `_unregister_lookup()` then manually calls `_clear_cached_lookups()`. | Pass. The manual clear is redundant after V1 but harmless; tests are not modified by this task. |

## Overrides

`ForeignObject` overrides `get_lookups()` with its own `lru_cache`, but it does
not override `_unregister_lookup()` or `_clear_cached_lookups()`. Because
`_clear_cached_lookups()` calls `subclass.get_lookups.cache_clear()`, the
override remains compatible with the invalidation mechanism. Compatibility:
pass.

## Compatibility Finding

No public API, virtual dispatch, method signature, or producer/consumer shape
requires a V2 code change.

